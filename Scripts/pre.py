#!/usr/bin/python2.7
# Used to load stuff the modules need before running
# (reads the config file to find whats needed)

import yaml
import os.path


def prepConfiguration():
    enabled_modules_list = []
    # open the configuration file in read mode
    with open('config', 'w') as outfile, open('config.yml', 'r') as config_file:
        # now load the yaml
        config_info = yaml.load(config_file)
        # fetch status
        for module in config_info:
            if config_info[module]['enabled'] is True:
                enabled_modules_list.append(module)
                # building the basic config line
                line = module
                if 'elements' in config_info[module]:
                    elements = config_info[module]['elements']
                    ## print "Elements status = {}".format(elements)
                    # check for needed elements
                    for element, value in config_info[module]['elements'].iteritems():
                        if value is True:
                            line += " {}".format(element)
                outfile.write(line + "\n")
                # line output "enabled_module enabled_element_1 enabled_element_2..."
        return enabled_modules_list

# read the configuration file
enabled_modules = prepConfiguration()
## print "Modules enabled = {}".format(enabled_modules)
# run according to config
for module in enabled_modules:
    file_name = "Scripts/{}.py".format(module)
    if os.path.isfile(file_name):
        os.system(file_name)
