#!/bin/bash

set -ex

# get last directory and chop the trailing slash
VERSION=$(cat /var/www/tinge/version.txt)

mv /var/www/tinge/current_deployment/$VERSION /var/www/tinge/versions/$VERSION
# symlink the dir
ln -snf /var/www/tinge/versions/$VERSION /var/www/tinge/current

# set owner
chown -R deploy:deploy /var/www/tinge/versions

# restart
passenger-config restart-app /var/www/tinge/current
