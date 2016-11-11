#!/usr/bin/python2.7
# Used to load stuff the modules need before running
# (reads the config file to find whats needed)

import yaml
import os.path


def readConfiguration():
    enabled_modules_dict = {}
    # open the configuration file in read mode
    config_file = open('config.yml', 'r')
    # now load the yaml
    config_info = yaml.load(config_file)

    for module in config_info:
        enabled_modules_dict[module] = config_info[module]['enabled']

    return enabled_modules_dict

# read the configuration file
enabled_modules = readConfiguration()
# run according to config
for module in enabled_modules:
    file_name = "Scripts/{}.py".format(module)
    if os.path.isfile(file_name) and enabled_modules[module] is True:
        os.system(file_name)
