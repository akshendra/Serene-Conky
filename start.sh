#!/bin/sh

conky -c co_main > log &
conky -c co_weather > log &
conky -c co_fact > log &
conky -c co_quote > log &