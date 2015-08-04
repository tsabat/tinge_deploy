#!/bin/bash

set -ex

# get to version dir
cd /var/www/tinge/versions

# get last directory and chop the trailing slash
VERSION=$(ls -d */ | head -1 | sed -e 's#/$##')

# symlink the dir
ln -snf /var/www/tinge/versions/$VERSION /var/www/tinge/current

# set owner
chown -R deploy:deploy /var/www/tinge/versions

# restart
passenger-config restart-app /var/www/tinge/current
