from copy import deepcopy
import glob
import os
import re
import shutil
import stat
import textwrap
import yaml

import GPS
import gps_utils
import workflows.promises as promises
from workflows import task_workflow

import libadalang as lal

try:
    from pip import main as pipmain
except:
    from pip._internal import main as pipmain

def del_rw(action, name, exc):
    os.chmod(name, stat.S_IWRITE)
    os.remove(name)


class ArduinoWorkflow:

    __plugin_deps = [
        "shapely"  # used during the geolookup generation
    ]

    __conf_files = {
        'build_options' : {
            'filename' : 'build.options.json',
            'path' : None
        },
        'flash_options' : {
            'filename' : 'uno.flash.yaml',
            'path' : None
        },
        'avrconf' : {
            'filename' : 'avrdude.conf',
            'path' : None
        },
        'openocdconf' : {
            'filename' : 'openocd.cfg',
            'path' : None
        }
    }

    __consts = {
        # after CCG completes, the post_ccg function pulls the .c and .h files from
        #   ccg_output and copies them into a compatible Arduino project folder (renames .c to .cpp)
        'ccg_lib' : os.path.join(GPS.pwd(), "lib"),

        # This is the directory where all the conf files for the build process live
        'conf_dir' : os.path.join(GPS.pwd(), "conf"),

        # passed to arduino-builder
        'logger' : "human",

        # The output of arduino-builder is put here
        'build_path' : os.path.join(GPS.pwd(), ".build"),

        'build_cmd' : "arduino-builder",

        'uno_flash_cmd' : "avrdude",
        'hifive_flash_cmd' : "/home/tice/.arduino15/packages/sifive/tools/openocd/9bab0782d313679bb0bfb634e6e87c757b8d5503/bin/openocd",

        'gnatls_cmd' : "c-gnatls",

        'geolookup_ads': os.path.join(GPS.pwd(), 'src', 'algos', 'line_finder', 'geo_filter.ads')
    }

    __rtl_dep_list = []

    # This contains the list of registered workflows and associated action descriptions.
    #    this is initilized from the __init__
    __workflow_registry = []

    def __get_conf_paths(self):
        """
        Search for conf files in the conf path and populate the conf_dic dictionary

        :return: True if all the conf files are found, False if one or more are not
        """

        temp_conf = deepcopy(self.__conf_files)

        build_type = GPS.Project.root().scenario_variables()['board']
        temp_conf['build_options']['filename'] = build_type + "." + temp_conf['build_options']['filename']

        conf_list = os.listdir(self.__consts['conf_dir'])
        for key, value in temp_conf.iteritems():
            if value['filename'] in conf_list:
                self.__conf_files[key]['path'] = os.path.join(self.__consts['conf_dir'], value['filename'])
            else:
                self.__error_exit("Could not find %s in directory %s" % (value['filename'], self.__consts['conf_dir']))
                return False
        return True

    def __read_flashfile(self):
        """
        Reads data from the flash.yaml file

        The information in flash.yaml describes the hardware and
        communication port to the avrdude executable

        :return: The python dictionary representation of the yaml file

        """
        conf = self.__conf_files['flash_options']['path']
        with open(conf) as datafile:
            return yaml.load(datafile)


    def __get_build_cmd(self, sketch):
        """
        Returns the full command line to build the Arduino project

        :param sketch: This is the filename of the arduino sketch found in the project

        :return: The list that corresponds to the build command
        """

        return [
            self.__consts['build_cmd'],
            "-compile",
            "-logger=%s" % self.__consts['logger'],
            "-build-options-file=%s" % self.__conf_files['build_options']['path'],
            "-build-path=%s" % self.__consts['build_path'],
            "-verbose",
            sketch
        ]


    def __get_flash_cmd(self, flash_options, sketch):
        """
        Returns the full command line to flash the Arduino

        :param flash_options: This is the yaml dictionary read from the flash config file

        :param sketch: this is the filename of the arduino sketch found in the project

        :return: The list that corresponds to the flash command
        """
        ret = []


        build_type = GPS.Project.root().scenario_variables()['board']

        if build_type == 'uno':
            ret = [
                self.__consts['uno_flash_cmd'],
                "-C%s" % self.__conf_files['avrconf']['path'],
                "-v",
                "-v",
                "-p%s" % flash_options['partno'],
                "-carduino",
                "-P%s" % flash_options['com_port'],
                "-b%s" % flash_options['baud_rate'],
                "-D",
                "-Uflash:w:%s:i" % os.path.join(self.__consts['build_path'], sketch + ".hex")
            ]
        elif build_type == 'hifive':
            ret = [
                self.__consts['hifive_flash_cmd'],
                "-s",
                self.__consts['conf_dir'],
                "-f",
                self.__conf_files['openocdconf']['path'],
                "-c",
                '''flash protect 0 64 last off''',
                "-c",
                '''program %s verify''' % os.path.join(self.__consts['build_path'], sketch + ".elf"),
                "-c",
                '''resume 0x20400000''',
                "-c",
                '''exit'''
            ]
        return ret


    def __get_gnatls_cmd(self, dir):
        alis = []
        for d in dir:
            alis.extend(glob.glob(os.path.join(d, "*.ali")))
        retval =  [
            self.__consts['gnatls_cmd'],
            "-d",
            "-a",
            "-s"
        ]
        retval.extend(alis)
        return retval


    def __get_runtime_deps(self, dir):
        self.__console_msg("Generating RTL dependency list.")
        try:
            proc = promises.ProcessWrapper(self.__get_gnatls_cmd(dir))
        except:
            self.__error_exit("Failed to run cmd for runtime deps")
            return

        ret, output = yield proc.wait_until_terminate()
        if ret is not 0:
            self.__error_exit(output)
            self.__error_exit("Could not get runtime deps.")
            return

        src_list = [os.path.basename(x.name().lower()) for x in GPS.Project.root().sources()]

        # this fugly line strips all blank lines out of the gnatls output, and removes all duplicates and src_files
        ada_dep_list = set([re.sub('adainclude', 'adalib', x) for x in (line.strip() for line in output.splitlines()) if x and x not in src_list])


        dep_list = set()
        for line in ada_dep_list:
            fpath, fn_wext = os.path.split(line)
            fn_next = os.path.splitext(fn_wext)[0]
            cfile = os.path.join(fpath, fn_next + '.c')
            hfile = os.path.join(fpath, fn_next + '.h')
            if os.path.isfile(cfile):
                dep_list.add(cfile)
            if os.path.isfile(hfile):
                dep_list.add(hfile)
        self.__rtl_dep_list = list(dep_list)

    def __post_ccg(self, obj_dir, clean=True):
        """
        This function handles post processing files to convert the CCG output into a
        format that the Arduino build system can understand

        CCG dumps .c and .h files into the obj_dir directory. This function copies
        those files into ccg_lib/src in order to setup an Arduino compatible build directory.


        :param clean: this tells the function to clean artifacts from the previous build.
                    The ccg_lib and build_path directories are cleaned.

                    Build_path should be cleaned because of a weird Arduino quirk where
                    iteractive builds are nested. So if you keep building you WILL run into
                    the max path character limit problem on Windows.

        """
        if clean:
            for files in os.listdir(os.path.join(self.__consts['ccg_lib'], "src")):
                if files.endswith(tuple(['.stderr', '.stdout'])):
                    os.remove(os.path.join(self.__consts['ccg_lib'], "src", files))


        ret, output = yield self.__get_runtime_deps(obj_dir)
        if ret is not 0:
            self.__error_exit("Could not get RTL dependencies")
            return

        for files in self.__rtl_dep_list:
            shutil.copy2(files, os.path.join(self.__consts['ccg_lib'], "src"))


    def __pre_arduino_build(self, clean=True):
        if not self.__get_conf_paths():
            return None
        if clean:
            if os.path.isdir(self.__consts['build_path']):
                for file in os.listdir(self.__consts['build_path']):
                    if os.path.isdir(os.path.join(self.__consts['build_path'], file)):
                        shutil.rmtree(os.path.join(self.__consts['build_path'], file), onerror=del_rw)
                    else:
                        if file != ".gitignore":
                            os.remove(os.path.join(self.__consts['build_path'], file))

        sketches = glob.glob('*.ino')
        if len(sketches) is not 1:
            self.__error_exit("Could not find sketch file.")
            return
        self.__console_msg("Found Arduino sketch %s" % sketches[0])
        return sketches[0]


    def __console_msg(self, msg, mode="text"):
        GPS.Console("Messages").write(msg + "\n", mode=mode)


    def __error_exit(self, msg=""):
        self.__console_msg(msg, mode="error")
        self.__console_msg("[workflow stopped]", mode="error")


    def __do_build_all_wf(self, task):
        totaltasks = 0
        for value in self.__workflow_registry:
            if value['all-flag']:
                totaltasks += value['tasks']

        self.__console_msg("Task total: %d" % totaltasks)

        taskcounter = 1
        for value in self.__workflow_registry:
            if value['all-flag']:
                self.__console_msg("Running task: %s" % value['name'])
                ret, output = yield value['func'](task, taskcounter, totaltasks)
                if ret is not 0:
                    self.__error_exit("Failed workflow task %s." % value['name'])
                    return
                taskcounter += value['tasks']

    def __generate_geolookup_table(self):
        import sys
        sys.path.append(".")
        import utils.graph as graph

        def update_lalctx(file):
            ctx = lal.AnalysisContext()
            return ctx.get_from_file(file)

        f = self.__consts['geolookup_ads']

        ######################################
        ##  Search and replace lookup table ##
        ######################################

        unit = update_lalctx(f)
        if unit.root is None:
            self.__error_exit("Could not parse %s." % f)
            for diag in unit.diagnostics:
                self.__error_exit('   {}'.format(diag))
            return False

        corner_node = unit.root.findall(lambda n: n.is_a(lal.NumberDecl) and n.f_ids.text=='Corner_Coord')

        if len(corner_node) != 1:
            self.__error_exit("Error parsing file for Corner_Coord")
            return False

        value = int(corner_node[0].f_expr.text)
        grph = graph.graph(value)
        array = grph.synthesizeArray()
        array_str = grph.array2String(array)

        array_node = unit.root.findall(lambda n: n.is_a(lal.ObjectDecl) and n.f_ids.text=='AvgPoint2StateLookup')
        if len(array_node) != 1:
            self.__error_exit("Error parsing file for AvgPoint2StateLookup")
            return False

        agg_start_line = int(array_node[0].f_default_expr.sloc_range.start.line)
        agg_start_col = int(array_node[0].f_default_expr.sloc_range.start.column)

        agg_end_line = int(array_node[0].f_default_expr.sloc_range.end.line)
        agg_end_col = int(array_node[0].f_default_expr.sloc_range.end.column)

        buf = GPS.EditorBuffer.get(GPS.File(f))
        agg_start_cursor = buf.at(agg_start_line, agg_start_col)
        agg_end_cursor = buf.at(agg_end_line, agg_end_col)

        buf.delete(agg_start_cursor, agg_end_cursor)
        fixed_array_str = textwrap.fill(array_str, width=78, initial_indent=' ' * 28, subsequent_indent=' ' * 29)
        buf.insert(agg_start_cursor, fixed_array_str[agg_start_col - 1:])

        #############################
        ##  Update radii threshold ##
        #############################

        unit = update_lalctx(f)
        if unit.root is None:
            self.__error_exit("Could not parse %s." % f)
            for diag in unit.diagnostics:
                self.__error_exit('   {}'.format(diag))
            return False

        radii_node = unit.root.findall(lambda n: n.is_a(lal.NumberDecl) and n.f_ids.text=='Radii_Threshold')
        if len(radii_node) != 1:
            self.__error_exit("Error parsing file for Radii_Threshold")
            return False

        radii_start_line = int(radii_node[0].f_expr.sloc_range.start.line)
        radii_start_col = int(radii_node[0].f_expr.sloc_range.start.column)

        radii_end_line = int(radii_node[0].f_expr.sloc_range.end.line)
        radii_end_col = int(radii_node[0].f_expr.sloc_range.end.column)

        radii_start_cursor = buf.at(radii_start_line, radii_start_col)
        radii_end_cursor = buf.at(radii_end_line, radii_end_col)

        buf.delete(radii_start_cursor, radii_end_cursor)
        new_radii = str(grph.radii) + ";"
        buf.insert(radii_start_cursor, new_radii)

        return True

    def __do_ccg_wf(self, task, start_task_num=1, end_task_num=4):
        #####################################
        ## Task - Generate geolookup table ##
        #####################################
        task.set_progress(start_task_num, end_task_num)
        if not self.__generate_geolookup_table():
            self.__error_exit("Failed to generate lookup tables...")
            return

        ##########################
        ## Task    - CCG        ##
        ##########################
        task.set_progress(start_task_num + 1, end_task_num)
        for file in os.listdir(os.path.join(self.__consts['ccg_lib'], "src")):
            if os.path.isdir(os.path.join(self.__consts['ccg_lib'], "src", file)):
                shutil.rmtree(os.path.join(self.__consts['ccg_lib'], "src", file), onerror=del_rw)
            else:
                os.remove(os.path.join(self.__consts['ccg_lib'], "src", file))


        self.__console_msg("Generating C code.")
        builder = promises.TargetWrapper("Build All")
        task.set_progress(start_task_num, end_task_num)
        retval = yield builder.wait_on_execute()
        if retval is not 0:
            self.__error_exit("Failed to generate C code.")
            return

        obj_dir = GPS.Project.root().object_dirs()

        ##############################
        ## Task   - post processing ##
        ##############################
        self.__console_msg("Post-processing CCG output.")
        retval, output = yield self.__post_ccg(obj_dir=obj_dir)
        if retval is not 0:
            self.__error_exit("Failed to post-process CCG output.")
            return
        task.set_progress(start_task_num + 2, end_task_num)

        ########################################
        ## Task - build project documentation ##
        ########################################
        self.__console_msg("Building project documentation.")
        gnatdoc = promises.TargetWrapper("gnatdoc")
        retval = yield gnatdoc.wait_on_execute(extra_args=["-P", GPS.Project.root().file().path, "-l"])
        if retval is not 0:
            self.__error_exit("Failed to generate project documentation.")
            return
        task.set_progress(start_task_num + 3, end_task_num)


    def __do_arduino_build_wf(self, task, start_task_num=1, end_task_num=2):
        ##########################
        ## Task    - Probe dir  ##
        ##########################

        sketch = self.__pre_arduino_build()

        task.set_progress(start_task_num, end_task_num)

        ####################################
        ## Task   - Build Arduino Project ##
        ####################################

        self.__console_msg("Building Arduino project.")
#        self.__console_msg(' '.join(self.__get_build_cmd(sketch=sketch)))
        try:
            proc = promises.ProcessWrapper(self.__get_build_cmd(sketch=sketch), spawn_console="")
        except:
            self.__error_exit("Could not launch Arduino build...")
            return
        ret, output = yield proc.wait_until_terminate()
        if ret is not 0:
            self.__error_exit("{} returned an error.".format(self.__get_build_cmd(sketch=sketch)[0]))
            return
        task.set_progress(start_task_num + 1, end_task_num)


    def __do_arduino_flash_wf(self, task, start_task_num=1, end_task_num=2):

        ##########################
        ## Task    - Probe dir  ##
        ##########################

        sketches = glob.glob('*.ino')
        if len(sketches) is not 1:
            self.__error_exit("Could not find sketch file.")
            return
        sketch = sketches[0]
        self.__console_msg("Found Arduino sketch %s" % sketch)

        if not self.__get_conf_paths():
            return
        flash_options = self.__read_flashfile()

        task.set_progress(start_task_num, end_task_num)

        ###################################
        ## Task - Flash image to board ##
        ###################################

        self.__console_msg("Flashing image to board.")
 #       self.__console_msg(' '.join(self.__get_flash_cmd(flash_options=flash_options, sketch=sketch)))
        try:
            proc = promises.ProcessWrapper(self.__get_flash_cmd(flash_options=flash_options, sketch=sketch), spawn_console="")
        except:
            self.__error_exit("Could not launch avrdude.")
            return

        ret, output = yield proc.wait_until_terminate()
        if ret is not 0:
            self.__error_exit("Flash to board failed.")
            return

        self.__console_msg("Flashing complete.")

        task.set_progress(start_task_num + 1, end_task_num)


    def __install_plugin_deps(self):
        ret = pipmain(["install"] + self.__plugin_deps)

        if ret is not 0:
            self.__error_exit("Unable to install plugin dependencies.")
            return False

        return True

    def __init__(self):
        """
        This is the entry point to the plugin.

        workflow_registry is the list that contains the workflows of the project.

        each workflow gets its own button and menu item.

        There is a build all which will run all workflows in the order specified in the list
        """

        if not self.__install_plugin_deps():
            raise Exception("Failed to install plugin dependencies.")

        GPS.Menu.create("/Build/Arduino")
        self.__workflow_registry = [
            {
                'name' : "Build & Flash",
                'description' : 'Run ccg, Build Arduino Project, and Flash to Board',
                'func' : self.__do_build_all_wf,
                'tasks' : 0,
                'all-flag' : False
            },
            {
                'name' : "Generate C Code",
                'description' : 'Generate C code and Arduino lib',
                'func' : self.__do_ccg_wf,
                'tasks' : 3,
                'all-flag' : True
            },
            {
                'name' : "Build Arduino Project",
                'description' : 'Build Arduino Project',
                'func': self.__do_arduino_build_wf,
                'tasks' : 2,
                'all-flag' : True
            },
            {
                'name' : "Flash Arduino",
                'description' : 'Flash Arduino Project to Board',
                'func' : self.__do_arduino_flash_wf,
                'tasks' : 2,
                'all-flag' : True
            }
        ]

        for value in self.__workflow_registry:
            value['action'] = gps_utils.make_interactive(
                callback=lambda x=value: task_workflow(x['name'], x['func']),
                category="Build",
                name=value['name'],
                toolbar='main',
                menu='/Build/Arduino/' + value['name'],
                description=value['description'])

        self.__console_msg("Plugin successfully initialized...")

    def cleanup(self):
        for value in self.__workflow_registry:
            value['action'][0].destroy_ui()

pluginRef = None

def initialize_project_plugin():
    """
    Entry point hook to GPS
    """
    global pluginRef

    try:
        pluginRef = ArduinoWorkflow()
    except Exception as inst:
        GPS.Console("Messages").write(inst.args[0] + "\n", mode="error")

def finalize_project_plugin():
    global pluginRef

    pluginRef.cleanup()
    del globals()[pluginRef]
