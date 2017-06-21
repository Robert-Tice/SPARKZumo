import fileinput
import glob
import json
import os
import re
import shutil
import stat

import GPS
import gps_utils
import workflows
import workflows.promises as promises
from workflows import task_workflow

def del_rw(action, name, exc):
    os.chmod(name, stat.S_IWRITE)
    os.remove(name)


class ArduinoWorkflow:

    __conf_files = {
        'build_options' : {
            'filename' : 'build.options.json',
            'path' : None
        },
        'flash_options' : {
            'filename' : 'flash.json',
            'path' : None
        },
        'avrconf' : {
            'filename' : 'avrdude.conf',
            'path' : None
        }
    }

    __consts = {
        # after SPARK-to-C completes, the post_ccg function pulls the .c and .h files from
        #   ccg_output and copies them into a compatible Arduino project folder (renames .c to .cpp)
        'ccg_lib' : os.path.join(GPS.pwd(), "lib"),

        # This is the directory where all the conf files for the build process live
        'conf_dir' : os.path.join(GPS.pwd(), "conf"),

        # passed to arduino-builder
        'logger' : "human",

        # The output of arduino-builder is put here
        'build_path' : os.path.join(GPS.pwd(), ".build"),

        'build_cmd' : "arduino-builder",

        'flash_cmd' : "avrdude",

        'gnatls_cmd' : "c-gnatls",

    }

    __rtl_dep_list = []

    # This contains the list of registered workflows and associated action descriptions.
    #    this is initilized from the __init__
    __workflow_registry = []     

    __arduino_console_timeout = None 
    __arduino_console_ser_inst = None 
    __arduino_console_inst = None


    def __get_conf_paths(self):
        """
        Search for conf files in the conf path and populate the conf_dic dictionary

        :return: True if all the conf files are found, False if one or more are not
        """
        conf_list = os.listdir(self.__consts['conf_dir'])
        for key, value in self.__conf_files.iteritems():
            if value['filename'] in conf_list:
                value['path'] = os.path.join(self.__consts['conf_dir'], value['filename'])
            else:
                self.__error_exit("Could not find %s in directory %s" % (value['filename'], self.__consts['conf_dir']))
                return False 
        return True


    def __read_flashfile(self):
        """
        Reads data from the flash.json file

        The information in flash.json describes the hardware and 
        communication port to the avrdude executable

        :return: The python dictionary representation of the json file

        """
        conf = self.__conf_files['flash_options']['path']
        with open(conf) as datafile:
            return json.load(datafile)


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
 #           "-quiet",
            "-verbose",
            sketch
        ]


    def __get_flash_cmd(self, flash_options, sketch):
        """
        Returns the full command line to flash the Arduino

        :param flash_options: This is the json dictionary read from the flash config file

        :param sketch: this is the filename of the arduino sketch found in the project

        :return: The list that corresponds to the flash command 
        """

        return [
            self.__consts['flash_cmd'],
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


    def __get_gnatls_cmd(self, obj_dir):
        obj_dir_ext = [os.path.join(s, "*.ali") for s in obj_dir]
        retval =  [
            self.__consts['gnatls_cmd'],
            "-d",
            "-a",
            "-s"
        ]
        retval.extend(obj_dir_ext)
        return retval


    def __get_runtime_deps(self, obj_dir):
        self.__console_msg("Generating RTL dependency list.")
        try:
            proc = promises.ProcessWrapper(self.__get_gnatls_cmd(obj_dir))
        except:
            self.__error_exit("Failed to run cmd for runtime deps")
            return

        ret, output = yield proc.wait_until_terminate()
        if ret is not 0:
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
        This function handles post processing files to convert the SPARK-to-C output into a
        format that the Arduino build system can understand

        SPARK-to-C dumps .c and .h files into the obj_dir directory. This function copies
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
                shutil.rmtree(self.__consts['build_path'], onerror=del_rw)

        if not os.path.isdir(self.__consts['build_path']):
            os.mkdir(self.__consts['build_path'])

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


    def __do_ccg_wf(self, task, start_task_num=1, end_task_num=2):
        ##########################
        ## Task    - SPARK-to-C ##
        ##########################
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

        task.set_progress(start_task_num + 1, end_task_num)


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


    # def __ardunio_console_callback(self):
    #     num_waiting = self.__arduino_console_ser_inst.in_waiting()
    #     if num_waiting > 0:
    #         x = self.__arduino_console_ser_inst.read(num_waiting)
    #         self.__arduino_console_inst.write(x.decode("utf-8"))

    # def __arduino_console_destroy(self):
    #     self.__arduino_console_timeout.remove()
    #     self.__arduino_console_ser_inst.close()
    #     self.__arduino_console_ser_inst = None
    #     self.__arduino_console_timeout = None


    # def __do_arduino_console_wf(self, task, start_task_num=1, end_task_num=1):
    #     self.__console_msg("Opening console connection to Arduino")
    #     self.__arduino_console_inst = GPS.Console("Arduino Console", on_destroy=self.__arduino_console_destroy)

    #     if not self.__get_conf_paths():
    #         return
    #     flash_options = self.__read_flashfile()

    #     try:
    #         self.__arduino_console_ser_inst = serial.Serial(flash_options['com_port'], int(flash_options['baud_rate']), timeout=0)
    #     except:
    #         self.__error_exit("Could not connect to Arduino console.")
    #         return

    #     self.__arduino_console_timeout = GPS.Timeout(200, self.__ardunio_console_callback)



    def __init__(self):
        """
        This is the entry point to the plugin.

        workflow_registry is the list that contains the workflows of the project.

        each workflow gets its own button and menu item.

        There is a build all which will run all workflows in the order specified in the list
        """
        GPS.Menu.create("/Build/Arduino")
        self.__workflow_registry = [
            {
                'name' : "Generate C Code",
                'description' : 'Generate C code and Arduino lib',
                'func' : self.__do_ccg_wf,
                'tasks' : 2,
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


        if len(self.__workflow_registry) > 1:
            gps_utils.make_interactive(
                    callback=lambda: task_workflow("Build all", self.__do_build_all_wf), 
                    category= "Build", 
                    name="Build and Flash", 
                    toolbar='main',
                    menu='/Build/Arduino/Build All', 
                    description='Run ccg, Build Arduino Project, and Flash to Board')

        # gps_utils.make_interactive(
        #             callback=self.__do_arduino_console_wf, 
        #             category= "Build", 
        #             name="Arduino Console", 
        #             toolbar='main',
        #             menu='/Build/Arduino/Arduino Console', 
        #             description='View Arduino Console data')

        for value in self.__workflow_registry:
            gps_utils.make_interactive(
                callback=lambda x=value: task_workflow(x['name'], x['func']),
                category="Build",
                name=value['name'],
                toolbar='main',
                menu='/Build/Arduino/' + value['name'],
                description=value['description'])


def initialize_project_plugin():
    """
    Entry point hook to GPS
    """
    ArduinoWorkflow()
 