#!/bin/bash

# Stop nginx
sudo systemctl stop nginx.service

# Stop uWSGI
sudo systemctl stop uwsgi.service