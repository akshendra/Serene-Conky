#!/usr/bin/python2.7
import re
import os
import json
import yaml
import forecastio
import datetime

def readConfiguration():
    # open the configuration file in read mode
    config_file = open('config.yml', 'r')
    # now load the yaml
    config = yaml.load(config_file)
    return config


def readWeather(config):

    # connect to forecast.io
    forecast = forecastio.load_forecast(config['weather']['key'], config['weather']['latitude'], config['weather']['longitude'], units=config['weather']['units'])

    # get the current weather
    current = forecast.currently()
    # get the details fo the current weather
    data = dict()
    data['temperature'] = int(current.temperature)
    data['summary'] = current.summary
    data['icon'] = current.icon
    data['feel'] = int(current.apparentTemperature)
    data['wind'] = current.windSpeed
    data['humidity'] = current.humidity
    data['update_at'] = current.time

    # now lets get the daily forecast
    daily = forecast.daily()
    data['forecast_summery'] = daily.summary.encode('utf-8')
    # get day by day data
    day_index = 1 # with 1 being today
    for day in daily.data:
        data[str(day_index) + '_' + 'minTemp'] = day.temperatureMin
        data[str(day_index) + '_' + 'minTempAt'] = datetime.datetime.fromtimestamp(int(day.temperatureMinTime)).strftime('%H:%M')
        data[str(day_index) + '_' + 'maxTemp'] = day.temperatureMax
        data[str(day_index) + '_' + 'maxTempAt'] = datetime.datetime.fromtimestamp(int(day.temperatureMaxTime)).strftime('%H:%M')
        data[str(day_index) + '_' + 'icon'] = day.icon
        data[str(day_index) + '_' + 'summary'] = day.summary
        day_index = day_index + 1

    # get the units
    units = config['weather']['units']
    # put the unit specific details
    if units == 'si':
        data['temp_unit'] = 'C'
        data['speed_unit'] = 'm/s'
    elif units == 'ca':
        data['temp_unit'] = 'C'
        data['speed_unit'] = 'km/h'
    else:
        data['temp_unit'] = 'F'
        data['wind_unit'] = 'mph'

    return data


def writeWeather(data):
    # open the file for writitng
    weather_file = open('Downloads/weather.cml', 'w')
    # write the weather
    for key in data:
        weather_file.write(key + ':' + str(data[key]) + '\n')
    # close the file
    weather_file.close()


# read the configuration
config = readConfiguration()

# read the weatther
data = readWeather(config)

# change the status
data['status'] = 'FILLED'

# write the weather
writeWeather(data)


