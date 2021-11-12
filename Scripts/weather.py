#! /usr/bin/python3

import requests
import yaml
from datetime import datetime
import json

OWM_ENDPOINT = "https://api.openweathermap.org/data/2.5/onecall"


def readConfiguration():
    # open the configuration file in read mode
    config_file = open('config.yml', 'r')
    # now load the yaml
    config = yaml.safe_load(config_file)
    return config


def get_icon_filename(icon, config):
    if config['weather']['color_icons']:
        return icon
    else:
        with open('Icons/icons.json', 'r') as icon_file:
            icon_dict = json.load(icon_file)
        icon_file = icon_dict[icon]
        return icon_file


def readWeather(config):
    api_params = {
        "appid": config['weather']['key'],
        "lat": config['weather']['latitude'],
        "lon": config['weather']['longitude'],
        "units": config['weather']['units'],
        "exclude": "hourly,minutely"
    }
    forecast = requests.get(url=OWM_ENDPOINT, params=api_params).json()

    # get the current weather
    current = forecast['current']
    # get the details fo the current weather
    data = dict()
    data['temperature'] = int(current['temp'])
    data['summary'] = current['weather'][0]['description']
    data['feel'] = int(current['feels_like'])
    data['wind'] = current['wind_speed']
    data['humidity'] = current['humidity']
    # ts = current['dt'] - forecast['timezone_offset']
    # data['update_at'] = datetime.utcfromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
    data['update_at'] = datetime.now()
    data['icon'] = get_icon_filename(current['weather'][0]['icon'], config)

    # now lets get the daily forecast
    daily = forecast['daily']
    try:
        data['forecast_summery'] = forecast['alerts'][0]['description']
    except KeyError:
        data['forecast_summery'] = daily[0]['weather'][0]['description'].title()


    # get day by day data
    day_index = 1 # with 1 being today
    for day in daily:
        data[str(day_index) + '_' + 'minTemp'] = day['temp']['min']
        data[str(day_index) + '_' + 'minTempAt'] = "N/A"
        data[str(day_index) + '_' + 'maxTemp'] = day['temp']['max']
        data[str(day_index) + '_' + 'maxTempAt'] = "N/A"
        data[str(day_index) + '_' + 'icon'] = get_icon_filename(day['weather'][0]['icon'], config)
        data[str(day_index) + '_' + 'summary'] = day['weather'][0]['main']
        day_index = day_index + 1

    # get the units
    units = config['weather']['units']
    # put the unit specific details
    if units == 'metric':
        data['temp_unit'] = 'C'
        data['speed_unit'] = 'm/s'
    elif units == 'standard':
        data['temp_unit'] = 'K'
        data['speed_unit'] = 'm/s'
    else:
        data['temp_unit'] = 'F'
        data['speed_unit'] = 'mph'

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
