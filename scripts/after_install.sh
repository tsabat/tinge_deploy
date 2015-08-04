#!/bin/bash

chown -R deploy:deploy /var/www/tinge/versions

cd /var/www/tinge/versions/
VERSION=$(ls -d */ | head -1 | sed -e 's#/$##')
ln -snf /var/www/tinge/versions/$VERSION /var/www/tinge/current

passenger-config restart-app /var/www/tinge/current
