#!/bin/sh
## setup enviroment

# setup the current resolution in the given config file 
setup_res ()
{
    dims=$(xdpyinfo  | grep 'dimensions:' | awk '{print $2}' | egrep -o '[0-9]+')
    width=$(echo $dims | awk '{print $1}')
    height=$(echo $dims | awk '{print $2}')
    minimum_width=$((${width}-200))
    minimum_height=$((${height}-200))

    new_line="	minimum_width = $minimum_width, minimum_height = $minimum_height,"
    old_line="	minimum_width = [0-9]*, minimum_height = [0-9]*,"

    sed -i "s/${old_line}/${new_line}/" $1
}

# clean temp files
clean_files ()
{
    rm -f log
    rm -f config
    rm -rf Downloads
}

setup_res main
clean_files
