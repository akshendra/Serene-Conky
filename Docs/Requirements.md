# Requirements:

This Conky theme requires python libraries of getting the data from the web, many of them will already be installed on the system, but if they are not you can install them using the instruction given below

## pip
We need a number of python libraries, first install pip
### On Ubuntu
    sudo apt-get install python3-pip
### On Fedora
    sudo yum install python3-pip
If their is any problem consult their [documentation](https://pip.pypa.io/en/stable/installing.html)

## pyyaml
This package is needed for parsing yaml files
### On Ubuntu
    sudo apt-get install python3-yaml
### On Fedora
    sudo yum install python3-yaml
### Using pip
    sudo pip install pyyaml

## BeautiFul Soup
For scrapping data out of html pages
### For Ubuntu
    sudo apt-get install python3-bs4
### Using pip
    sudo pip install bs4

## lxml
For parsing html
### For Ubuntu
    sudo apt-get install python3-lxml
### Using pip
    sudo pip install lxml

## Fonts
For displaying the correct fonts
create a `.fonts` folder under `$HOME` directory.
copy the 'Text Me One', 'Roboto' & 'Poiret One' fonts from [Fonts](../Fonts) to the newly created directory.

Then run `sudo fc-cache -fv`
