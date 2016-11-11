#!/bin/sh
# setup the current resolution in the config file

dims=$(xdpyinfo  | grep 'dimensions:' | awk '{print $2}' | egrep -o '[0-9]+')
minimum_width=$(echo $dims | awk '{print $1}')
minimum_height=$(echo $dims | awk '{print $2}')

new_line=$(echo $dims | awk '{print "	minimum_width = "$1", minimum_height = "$2","}')
old_line='	minimum_width = [0-9]*, minimum_height = [0-9]*,'

sed -i "s/${old_line}/${new_line}/" main
