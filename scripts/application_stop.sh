#!/bin/bash

# clean up
if [ -d /var/www/tinge/current_deployment ]; then
  rm -rf /var/www/tinge/current_deployment
fi

if [ -f /var/www/tinge/version.txt ]; then
  rm -rf /var/www/tinge/version.txt
fi
