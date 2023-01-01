#!/usr/intel/bin/python3.6.3a
import sys
import os
import subprocess
from configparser import ConfigParser
        
class build_so_file():
    def __init__(self):
        self.script_base_path = os.path.dirname(os.path.realpath(__file__))
        self.vc_model_path = os.path.join(self.script_base_path, "../../")
        self.config = self.get_config()
        self.makefile_executor_pointer_path = self.get_makefile_executor_pointer_path(self.config)
        self.makefile_path = self.get_makefile_path(self.config)
        self.build_so_cmd = self.makefile_executor_pointer_path + " " + self.makefile_path + " " + self.vc_model_path
        
    def get_makefile_executor_pointer_path(self, config):
        return os.path.join(self.vc_model_path, config["vcs_build_items"].get("makefile_executor_cmd"))

    def get_makefile_path(self, config):
        return os.path.join(self.vc_model_path, config["vcs_build_items"].get("makefile_path"))

    def get_config(self):
        config_path = os.path.join(self.script_base_path, "configuration/config.ini") 
        config = ConfigParser()
        config.read(config_path)
        return config
    
    def run(self):
        return_code = subprocess.run(self.build_so_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(return_code.stdout.decode())
        print(return_code.stderr.decode())
        
        
if __name__ == "__main__":
    so_file_build = build_so_file()
    so_file_build.run()
