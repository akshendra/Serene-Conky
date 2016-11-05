#!/bin/sh

conky -c co_system > log &
conky -c co_fact > log &
conky -c co_quote > log &
#conky -c co_weather > log &

