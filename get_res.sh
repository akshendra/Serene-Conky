#!/bin/sh

echo $(xdpyinfo  | grep 'dimensions:' | awk '{print $2}' | egrep -o '[0-9]+')

