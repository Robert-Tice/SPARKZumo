import json
import os
import shutil

import GPS
import gps_utils
import workflows
import workflows.promises as promises
from workflows import task_workflow


arduino_object = None


class ArduinoProject:

    __ucg_output = os.path.join(GPS.pwd(), "obj")
    __ucg_lib = os.path.join(GPS.pwd(), "lib")

    __button_action = None

    ## arduino-builder options
    __sketch = None     ## gets populated by init

    __logger = "machine"   

    __build_options = os.path.join(GPS.pwd(), "build.options.json")
    __build_path = None
    __build_cmd = "arduino-builder"
    ##

    __build_path = os.path.join(GPS.pwd(), "build")

    ## avrdude options
    __com_port = None
    __baud_rate = None
    __partno = None
    __flash_cmd = "avrdude"
    __avrconf = "avrdude.conf"
    ##


    def __init__(self):
        sketches = GPS.dir(pattern='*.ino')
        if len(sketches) is not 1:
            raise Exception
        self.__sketch = sketches[0]

        self.__read_flashfile()

        self.__button_action = gps_utils.make_interactive(
                                    callback=self.__arduino_process, 
                                    category= "Build", 
                                    name="Arduino Process", 
                                    toolbar='main', 
                                    description='Run UCG and build Arduino Project')


    def __read_flashfile(self):
        with open('flash.json') as datafile:
            data = json.load(datafile)

        self.__com_port = data['com_port']
        self.__partno = data['partno']
        self.__baud_rate = data['baud_rate']


    def __get_build_cmd(self):
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
        if clean:
            for files in os.listdir(os.path.join(self.__ucg_lib, "src")):
                if files.endswith('.cpp') or files.endswith('.h') or files.endswith('.c'):
                    os.remove(os.path.join(self.__ucg_lib, "src", files))
            if os.path.isdir(self.__build_path):
                shutil.rmtree(self.__build_path)

        if not os.path.isdir(self.__build_path):
            os.mkdir(self.__build_path)

        shutil.copy2(os.path.join(self.__ucg_output, ".gitignore"), self.__build_path)

        for files in os.listdir(self.__ucg_output):
            if files.endswith('.c'):
                if rename:
                    shutil.move(os.path.join(self.__ucg_output, files), 
                        os.path.join(self.__ucg_lib, "src", os.path.splitext(files)[0] + ".cpp"))
                else:
                    shutil.move(os.path.join(self.__ucg_output, files),
                        os.path.join(self.__ucg_lib, "src", files))
            elif files.endswith(".h"):
                shutil.move(os.path.join(self.__ucg_output, files), 
                    os.path.join(self.__ucg_lib, "src", files))


    def __console_msg(self, msg, mode="text"):
        GPS.Console("Messages").write(msg + "\n", mode=mode)


    def __error_exit(self, msg=""):
        self.__console_msg(msg, mode="error")
        self.__console_msg("[workflow stopped]", mode="error")


    def __do_wf(self, task):
        self.__console_msg("Generating C code.")
        builder = promises.TargetWrapper("Build All")
        task.set_progress(1, 5)
        r0 = yield builder.wait_on_execute()
        if r0 is not 0:
            self.__error_exit("Failed to generate C code.")
            return
        task.set_progress(2, 5)   

        self.__post_ucg()
        task.set_progress(3, 5)

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
        task.set_progress(4, 5)

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
        task.set_progress(5, 5)

        self.__console_msg("Flashing complete.")


    def __arduino_process(self):
        task_workflow("Arduino Build", self.__do_wf)


def initialize_project_plugin():
    arduino_object = ArduinoProject()
    

 