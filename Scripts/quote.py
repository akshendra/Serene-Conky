#! /usr/bin/python3

from bs4 import BeautifulSoup
import requests
import yaml


def readConfiguration():
    # open the configuration file in read mode    
    config_file = open('config.yml', 'r')
    # now load the yaml
    config = yaml.safe_load(config_file)
    return config


def readQuote(config):
    # get the quote page
    page = requests.get(config['quote']['url'])
    # make the soup
    soup = BeautifulSoup(page.text, "lxml")

    # lets find the quotes
    data = dict()
    quotes = soup.findAll(class_=["b-qt"])
    authors = soup.findAll(class_=["bq-aut"])
    for i in range(0, 5):
        data[str(i+1) + '_quote'] = quotes[i].text.strip()
        data[str(i+1) + '_author'] = authors[i].text    
    return data


def writeQuote(data):
    # open the file for writitng
    quote_file = open('Downloads/quote.cml', 'w')
    # write the weather
    for key in data:
        quote_file.write(key + ':' + str(data[key]) + '\n')
    # close the file
    quote_file.close()


# read the configuration file
config = readConfiguration()
# read the quotes
data = readQuote(config)
data['status'] = 'FILLED'
# write them to a file
writeQuote(data)
