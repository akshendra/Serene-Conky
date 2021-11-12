#!/bin/sh
killall conky
conky -c main > log &
