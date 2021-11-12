#! /usr/bin/python3

from bs4 import BeautifulSoup
import requests
from datetime import datetime
import yaml



def readConfiguration():
    # open the configuration file in read mode    
    config_file = open('config.yml', 'r')
    # now load the yaml
    config = yaml.safe_load(config_file)    
    return config


def readFact(config):
    # get the quote page
    fact_url = config['fact']['url']
    headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Accept-Language": "en-US,en",
        "TE": "trailers"
    }
    time_now = datetime.now().strftime('%d/%m/%Y %X')
    dates = "{ currentdates: \'" + time_now + "\'}"

    # get the fact
    data = dict()
    page = requests.post(url=fact_url, headers=headers, data=dates).json()['d'].strip("][")
    # pprint(page)
    soup = BeautifulSoup(page, "lxml")
    data['fact'] = soup(class_='sliderText')[0].text

    # lets find the quotes
    return data


def writeFact(data):
    # open the file for writing    
    fact_file = open('Downloads/fact.cml', 'w')
    # write the fact
    fact_file.write('fact:' + data['fact'])
    fact_file.write('\nstatus:' + data['status'])
    # close the file
    fact_file.close()


# read the configuration file
config = readConfiguration()
# read the quotes
data = readFact(config)
data['status'] = 'FILLED'
# write them to a file
writeFact(data)
