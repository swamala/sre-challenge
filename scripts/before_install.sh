#!/bin/bash

# Set working directory
cd /var/www/html/django_project/sre_challenge

/usr/bin/python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt