import glob
import json
import os
import shutil

import GPS
import gps_utils
import workflows
import workflows.promises as promises
from workflows import task_workflow



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
        # after SPARK-to-C completes, the post_ucg function pulls the .c and .h files from
        #   ucg_output and copies them into a compatible Arduino project folder (renames .c to .cpp)
        'ucg_lib' : os.path.join(GPS.pwd(), "lib"),

        # This is the directory where all the conf files for the build process live
        'conf_dir' : os.path.join(GPS.pwd(), "conf"),

        # passed to arduino-builder
        'logger' : "machine",

        # The output of arduino-builder is put here
        'build_path' : os.path.join(GPS.pwd(), ".build"),

        'build_cmd' : "arduino-builder",

        'flash_cmd' : "avrdude"
    }

    __workflow_registry = {}        


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


    def __post_ucg(self, obj_dir, clean = True, rename = True):
        """
        This function handles post processing files to convert the SPARK-to-C output into a
        format that the Arduino build system can understand

        SPARK-to-C dumps .c and .h files into the obj_dir directory. This function copies
        those files into ucg_lib/src in order to setup an Arduino compatible build directory.


        :param clean: this tells the function to clean artifacts from the previous build.
                    The ucg_lib and build_path directories are cleaned.

                    Build_path should be cleaned because of a weird Arduino quirk where 
                    iteractive builds are nested. So if you keep building you WILL run into 
                    the max path character limit problem on Windows.

        :param rename: This tells the function to rename .c files to .cpp in order to avoid a weird
                    compilation conflict with functions that were pragma Import'd

        """
        if clean:

            for files in os.listdir(os.path.join(self.__consts['ucg_lib'], "src")):
                if files.endswith(tuple(['.cpp', '.c', '.h'])):
                    os.remove(os.path.join(self.__consts['ucg_lib'], "src", files))
            if os.path.isdir(self.__consts['build_path']):
                shutil.rmtree(self.__consts['build_path'])

        if not os.path.isdir(self.__consts['build_path']):
            os.mkdir(self.__consts['build_path'])

        for dirs in obj_dir:
            for files in os.listdir(dirs):
                if files.endswith(tuple(['.c', '.h'])):
                    shutil.move(os.path.join(dirs, files),
                            os.path.join(self.__consts['ucg_lib'], "src", files))

        if rename:
            for files in glob.iglob(os.path.join(self.__consts['ucg_lib'], "src", '*.c')):
                os.rename(files, os.path.splitext(files)[0] + '.cpp')            


    def __console_msg(self, msg, mode="text"):
        GPS.Console("Messages").write(msg + "\n", mode=mode)


    def __error_exit(self, msg=""):
        self.__console_msg(msg, mode="error")
        self.__console_msg("[workflow stopped]", mode="error")


    def __do_build_all_wf(self, task):
        totaltasks = 0
        for key, value in self.__workflow_registry.iteritems():
            totaltasks += value['tasks']  

   #     self.__console_msg("Task total: %d" % totaltasks)

        taskcounter = 1
        for key, value in self.__workflow_registry.iteritems():
  #          self.__console_msg("Running task: %s" % key)
            ret = yield value['func'](task, taskcounter, totaltasks)
            if ret is not 0:
                return
            taskcounter += value['tasks']         


    def __do_spark_to_c_wf(self, task, start_task_num=1, end_task_num=2):
        ##########################
        ## Task    - SPARK-to-C ##
        ##########################
        self.__console_msg("Generating C code.")
        builder = promises.TargetWrapper("Build All")
        task.set_progress(start_task_num, end_task_num)
        r0 = yield builder.wait_on_execute()
        if r0 is not 0:
            self.__error_exit("Failed to generate C code.")
            return

        obj_dir = GPS.Project.root().object_dirs()       

        ##############################
        ## Task   - post processing ##
        ##############################
        self.__console_msg("Post-processing SPARK-to-C output.")
        self.__post_ucg(obj_dir=obj_dir)
        task.set_progress(start_task_num + 1, end_task_num)


    def __do_arduino_build_wf(self, task, start_task_num=1, end_task_num=2):
        ##########################
        ## Task    - Probe dir  ##
        ##########################

        sketches = glob.glob('*.ino')
        if len(sketches) is not 1:
            self.__error_exit("Could not find sketch file.")
            return
        sketch = sketches[0]
        self.__console_msg("Found Arduino sketch %s" % sketch)

        self.__get_conf_paths()

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
        r1, output = yield proc.wait_until_terminate()
        if r1 is not 0:
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

        self.__get_conf_paths()

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

        r2, output = yield proc.wait_until_terminate()
        if r2 is not 0:
            self.__error_exit("Flash to board failed.")
            return

        self.__console_msg("Flashing complete.")

        task.set_progress(start_task_num + 1, end_task_num) 


    def __init__(self):
        """
        This is the entry point to the plugin.
        """

        self.__workflow_registry = {
            'spark_to_c' : {
                            'func' : self.__do_spark_to_c_wf,
                            'tasks' : 2
                            },
            'arduino_build' : {
                            'func': self.__do_arduino_build_wf,
                            'tasks' : 2
                            },
            'arduino_flash' : {
                            'func' : self.__do_arduino_flash_wf,
                            'tasks' : 2
                            }
        }


        GPS.Menu.create("/Build/Arduino")
        gps_utils.make_interactive(
                callback=lambda: task_workflow("Build all", self.__do_build_all_wf), 
                category= "Build", 
                name="SPARK/Arduino Build All", 
                toolbar='main',
                menu='/Build/Arduino/Build All', 
                description='Run UCG, build Arduino Project, and Flash to Board')

        gps_utils.make_interactive( 
                callback=lambda: task_workflow("Run SPARK-to-C", self.__do_spark_to_c_wf),
                category= "Build", 
                name="Run SPARK-to-C", 
                toolbar='main',
                menu='/Build/Arduino/SPARK-to-C',  
                description='Generate C code and Arduino lib')

        gps_utils.make_interactive(
                callback=lambda: task_workflow("Arduino Build", self.__do_arduino_build_wf), 
                category= "Build", 
                name="Arduino Build", 
                toolbar='main',
                menu='/Build/Arduino/Build Arduino Project',  
                description='Build Arduino Project')

        gps_utils.make_interactive(
                callback=lambda: task_workflow("Arduino Flash", self.__do_arduino_flash_wf), 
                category= "Build", 
                name="Arduino Flash", 
                toolbar='main',
                menu='/Build/Arduino/Flash Arduino', 
                description='Flash Arduino Project to Board')



def initialize_project_plugin():
    """
    Entry point hook to GPS
    """
    ArduinoWorkflow()
 