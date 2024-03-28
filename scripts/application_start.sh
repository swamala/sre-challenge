#!/bin/bash

# Start webserver
sudo /var/www/html/django_project/sre_challenge/.venv/bin/uwsgi --socket /var/run/uwsgi/app/socket --module sre_challenge.wsgi:application --daemonize /var/log/uwsgi/sre-challenge.log
# Start reverse proxy
sudo systemctl start nginx.service