# Requirements:

This Conky theme requires python libraries of getting the data from the web, many of them will already be installed on the system, but if they are not you can install them using the instruction given below

## pip
We need a number of python libraries, first install pip
### On Ubuntu
    sudo apt-get install python-pip
### On Fedora
    sudo yum install python-pip
If their is any problem consult their [documentation](https://pip.pypa.io/en/stable/installing.html)

## pyyaml
This package is needed for parsing yaml files
### On Ubuntu
    sudo apt-get install python-yaml
### On Fedora
    sudo yum install python-yaml
### Using pip
    sudo pip install pyyaml

## python-forecast.io
The python wrapper for the forecast.io api
    sudo pip install python-forecastio

## BeautiFul Soup
For scrapping data out of html pages
### For Ubuntu
    sudo apt-get install python-bs4
### Using pip
    sudo pip install beautifulsoup4

## lxml
For parsing html
### For Ubuntu
    sudo apt-get install python-lxml
### Using pip
    sudo pip install lxml

## Fonts
For displaying the correct fonts
### For Ubuntu
Get Google’s fonts using TypeCatcher 
#### Install TypeCatcher
    sudo apt-get update & sudo apt-get install typecatcher
#### Use TypeCatcher to install the following:
    'Text Me One', 'Roboto' & 'Poiret One'