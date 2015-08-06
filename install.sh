#!/bin/bash

# exit on error
set -e
# print each line
set -o xtrace

###################
# Install passenger
###################

 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
 apt-get install -y apt-transport-https ca-certificates
 sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
 apt-get update
 apt-get install -y nginx-extras passenger

####################
# Create Deploy User
####################

useradd --create-home deploy

# NOTE: this is here to simulate the ubuntu user.  When you move this
# to an ansible script and run on production, this in not needed
mkdir -p /home/ubuntu/.ssh; touch /home/ubuntu/.ssh/authorized_keys

# copy the ssh authorized keys to the deploy user
mkdir -p ~deploy/.ssh
sh -c "cat /home/ubuntu/.ssh/authorized_keys >> ~deploy/.ssh/authorized_keys"
chown -R deploy: ~deploy/.ssh
chmod 700 ~deploy/.ssh
sh -c "chmod 600 ~deploy/.ssh/*"

#########################
## Install rbenv and ruby
#########################

apt-get install -y curl gnupg build-essential git-core libssl-dev libreadline-dev zlib1g-dev

## using a heredoc to run these commands as the deploy user
sudo -i -u deploy bash << 'HERE'
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash

## Install ruby version
. ~/.bash_profile
rbenv install 2.2.2
HERE

########################
## don't include on prod
########################

## Tim loves vim
apt-get install -y vim

## only needed for sqlite during the test
## you can remove this once we're in prod
apt-get install -y libsqlite3-dev

## needed for rails, but really only on the build box
apt-get install -y nodejs

########################
## configure app server
########################

# add the dictionary for the random words for revisions
apt-get install -y --reinstall wamerican

# enable passenger by uncommenting/replacing passenger_root and passenger_ruby
sed -i 's|^.*# passenger_ruby .*|        passenger_ruby /home/deploy/.rbenv/shims/ruby;|' /etc/nginx/nginx.conf
sed -i 's|^.*# passenger_root |        passenger_root |' /etc/nginx/nginx.conf

# grab the nginx default server from a gist.  This should be replaced with a template
# when you create an ansible script for this.
curl \
https://gist.githubusercontent.com/tsabat/18569c054a83f620c666/raw/c0e809599a07902ff5c60275431e8d7c42eb79e7/tinge.nginx.conf > \
/etc/nginx/sites-enabled/default

# set up app root
mkdir -p /var/www/tinge/versions
chown -R deploy:deploy /var/www/tinge

# install bundler
sudo -i -u deploy bash <<'HERE'
. ~/.bash_profile
rbenv shell 2.2.2
gem install bundler --no-rdoc --no-ri
HERE
