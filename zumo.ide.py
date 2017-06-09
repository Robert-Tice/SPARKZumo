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
        'build_path' : os.path.join(GPS.pwd(), "build"),

        'build_cmd' : "arduino-builder",

        'flash_cmd' : "avrdude"
    }


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
            "-quiet",
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


    def __do_wf(self, task):
        """
        This is the main workflow triggered by the button.

        The workflow steps are:
            1.) Call SPARK-to-C on the application to generate the C files
            2.) Probe directory for conf files and arduino sketch files
            3.) Call post_ucg to do the appropriate post processing
            4.) Call arduino-builder with the get_build_cmd data
            5.) Call avrdude with the get_flash_cmd data

        :param task: this is the task passed in from task_workflow. This
            is used to set_progress for the GPS progress bar


        """


        ##########################
        ## Task 1  - SPARK-to-C ##
        ##########################
        self.__console_msg("Generating C code.")
        builder = promises.TargetWrapper("Build All")
        task.set_progress(1, 4)
        r0 = yield builder.wait_on_execute()
        if r0 is not 0:
            self.__error_exit("Failed to generate C code.")
            return  

        ##########################
        ## Task 2  - Probe dir  ##
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

        obj_dir = GPS.Project.root().object_dirs()

        task.set_progress(2, 4) 

        ##############################
        ## Task 3 - post processing ##
        ##############################
        self.__console_msg("Post-processing SPARK-to-C output.")
        self.__post_ucg(obj_dir=obj_dir)
        task.set_progress(3, 4)

        ####################################
        ## Task 4 - Build Arduino Project ##
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
        task.set_progress(4, 4)

        ###################################
        ## Task 5 - Flash image to board ##
        ###################################

        self.__console_msg("Flashing image to board.")
        self.__console_msg(' '.join(self.__get_flash_cmd(flash_options=flash_options, sketch=sketch)))
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


    def __arduino_process(self):
        """
        Callback for the "Arduino Process" button

        Starts workflow
        """
        task_workflow("Arduino Build", self.__do_wf)



    def __init__(self):
        """
        This is the entry point to the plugin.
        """
        gps_utils.make_interactive(
                callback=self.__arduino_process, 
                category= "Build", 
                name="Arduino Process", 
                toolbar='main', 
                description='Run UCG and build Arduino Project')



def initialize_project_plugin():
    """
    Entry point hook to GPS
    """
    ArduinoWorkflow()
 