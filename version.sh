#!/bin/bash

set -ex

if [ -z "$1" ];
then
  NOW=$(date +"%Y-%m-%d_%k-%M-%S")
else
  echo 'using passed in value'
  NOW=$1
fi

REPO=https://github.com/tsabat/example_rails.git

sudo -i -u deploy bash <<HERE
set -ex

. ~/.bash_profile
rbenv shell 2.2.2
cd /var/www/tinge

if [ ! -d repo ]
then
  git clone $REPO repo
fi

cd repo
git pull origin master
bundle install --without test development --path vendor
RAILS_ENV=production bin/rake assets:precompile

cd ..
cp -r repo versions/$NOW
rm -rf versions/$NOW/.git
pwd
ln -snf /var/www/tinge/versions/$NOW /var/www/tinge/current
HERE
