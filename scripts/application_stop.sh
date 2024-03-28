#!/bin/bash

# Stop nginx
sudo systemctl stop nginx.service

# Search for all running uWSGI processes except the grep command itself
uwsgi_processes=$(ps -aux | grep '[u]wsgi' | awk '{print $2}')

# Check if there are any uWSGI processes running
if [ -n "$uwsgi_processes" ]; then
    echo "Stopping uWSGI processes gracefully..."
    
    # Loop through each uWSGI process and send SIGTERM
    for pid in $uwsgi_processes; do
        echo "Stopping uWSGI process with PID $pid..."
        kill -15 $pid
    done
    
    echo "All uWSGI processes stopped gracefully."
else
    echo "No uWSGI processes found running."
fi
