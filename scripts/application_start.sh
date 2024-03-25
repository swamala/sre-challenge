#!/bin/bash

# Start webserver
sudo systemctl start uwsgi.service

# Start reverse proxy
sudo systemctl start nginx.service