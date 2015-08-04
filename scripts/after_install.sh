#!/bin/bash

chown -R deploy:deploy /var/www/tinge/versions/REPLACE_VERSION
ln -snf /var/www/tinge/versions/REPLACE_VERSION /var/www/tinge/current

passenger-config restart-app /var/www/tinge/current
