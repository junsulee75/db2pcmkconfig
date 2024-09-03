#!/bin/bash

export PROMPT=0

menu.py 1,1,6   # Prereq. packages installation

menu.py 1,2,6    # Db2 installation
menu.py 1,3,6    # create DB2 instance
menu.py 1,4,6    # hadr configuration 
menu.py 1,5,6    # pacemaker setup   
