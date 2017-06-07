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

    # the output of SPARK-to-C goes here, specified in the gpr file
    __ucg_output = os.path.join(GPS.pwd(), "obj")

    # after SPARK-to-C completes, the post_ucg function pulls the .c and .h files from
    #   ucg_output and copies them into a compatible Arduino project folder (renames .c to .cpp)
    __ucg_lib = os.path.join(GPS.pwd(), "lib")

    # holds the tuple returned by make_interactive
    __button_action = None

    #############################
    ## arduino-builder options ##
    #############################

    # holds the sketch found during init_plugin
    __sketch = None

    # passed to arduino-builder
    __logger = "machine"   

    # build.options.json holds to arduino-builder config information
    __build_options = os.path.join(GPS.pwd(), "build.options.json")

    # The output of arduino-builder is put here
    __build_path = os.path.join(GPS.pwd(), "build")

    __build_cmd = "arduino-builder"

    #############################


    #############################
    ##     avrdude options     ##
    #############################

    # the com port used to communicate with the Arduino board
    #   read from flash.json
    __com_port = None

    # the baud rate to do the communication
    #   read from flash.json
    __baud_rate = None

    # the physical IC on the arduino
    #   read from flash.json
    __partno = None

    __flash_cmd = "avrdude"
    __avrconf = "avrdude.conf"

    #############################


    def __read_flashfile(self):
        """
        Reads data from the flash.json file

        The information in flash.json describes the hardware and 
        communication port to the avrdude executable

        """
        with open('flash.json') as datafile:
            data = json.load(datafile)

        self.__com_port = data['com_port']
        self.__partno = data['partno']
        self.__baud_rate = data['baud_rate']


    def __get_build_cmd(self):
        """
        Returns the full command line to build the Arduino project
        """

        retval = [
            self.__build_cmd,
            "-compile",
            "-logger=%s" % self.__logger,
            "-build-options-file=%s" % self.__build_options,
            "-build-path=%s" % os.path.join(self.__build_path),
            "-quiet",
            "-verbose",
            self.__sketch
        ]
        return retval


    def __get_flash_cmd(self):
        """
        Returns the full command line to flash the Arduino
        """

        retval = [
            self.__flash_cmd,
            "-C%s" % self.__avrconf,
            "-v",
            "-v",
            "-p%s" % self.__partno,
            "-carduino",
            "-P%s" % self.__com_port,
            "-b%s" % self.__baud_rate,
            "-D",
            "-Uflash:w:%s:i" % os.path.join(self.__build_path, self.__sketch + ".hex")
        ]
        return retval


    def __post_ucg(self, clean = True, rename = True):
        """
        This function handles post processing files to convert the SPARK-to-C output into a
        format that the Arduino build system can understand

        SPARK-to-C dumps .c and .h files into the ucg_ouput directory. This function copies
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

            for files in os.listdir(os.path.join(self.__ucg_lib, "src")):
                if files.endswith(tuple(['.cpp', '.c', '.h'])):
                    os.remove(os.path.join(self.__ucg_lib, "src", files))
            if os.path.isdir(self.__build_path):
                shutil.rmtree(self.__build_path)

        if not os.path.isdir(self.__build_path):
            os.mkdir(self.__build_path)

        shutil.copy2(os.path.join(self.__ucg_output, ".gitignore"), self.__build_path)

        for files in os.listdir(self.__ucg_output):
            if files.endswith(tuple(['.c', '.h'])):
                shutil.move(os.path.join(self.__ucg_output, files),
                        os.path.join(self.__ucg_lib, "src", files))

        if rename:
            for files in glob.iglob(os.path.join(self.__ucg_lib, "src", '*.c')):
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
            2.) Call post_ucg to do the appropriate post processing
            3.) Call arduino-builder with the get_build_cmd data
            4.) Call avrdude with the get_flash_cmd data

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
        task.set_progress(2, 4)   

        ##############################
        ## Task 2 - post processing ##
        ##############################

        self.__post_ucg()
        task.set_progress(3, 4)

        ####################################
        ## Task 3 - Build Arduino Project ##
        ####################################

        self.__console_msg("Building Arduino project.")
    #      self.__console_msg(' '.join(self.__get_build_cmd()))
        try:
            proc = promises.ProcessWrapper(self.__get_build_cmd(), spawn_console="")
        except:
            self.__error_exit("Could not launch Arduino build...")
            return
        r1, output = yield proc.wait_until_terminate()
        if r1 is not 0:
            self.__error_exit("{} returned an error.".format(self.__get_build_cmd()[0]))
            return
        task.set_progress(4, 4)

        ###################################
        ## Task 4 - Flash image to board ##
        ###################################

        self.__console_msg("Flashing image to board.")
        self.__console_msg(' '.join(self.__get_flash_cmd()))
        try:
            proc = promises.ProcessWrapper(self.__get_flash_cmd(), spawn_console="")
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

        This creates a task and calls the workflow self.__do_wf
        """
        task_workflow("Arduino Build", self.__do_wf)


    def __init__(self):
        """
        This is the entry point to the plugin.

        The plugin should find a *.ino file at the top level of the project.
        This is the base Arduino project driver and should call generated SPARK-to-C functions

        If the plugin cannot find an appropriate sketch at the top level it will fail to load the plugin.

        After a viable sketch is found, the flash.json file is processed by read_flashfile

        And finally a button is generated with a callback to the base workflow function arduino_process

        """
        sketches = glob.glob('*.ino')
        if len(sketches) is not 1:
            self.__error_exit("Could not find sketch file.")
            return
        self.__sketch = sketches[0]
        self.__console_msg("Found Arduino sketch %s" % self.__sketch)

        self.__read_flashfile()

        self.__button_action = gps_utils.make_interactive(
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
    

 