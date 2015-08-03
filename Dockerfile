FROM ubuntu:14.04

## Install passenger

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 && \
    apt-get install -y apt-transport-https ca-certificates && \
    sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list' && \
    apt-get update && \
    apt-get install -y nginx-extras passenger

## Create Deploy User

RUN useradd --create-home deploy

## NOTE: this is here to simulate the ubuntu user.  When you move this
# to an ansible script and run on production, this in not needed
RUN mkdir -p /home/ubuntu/.ssh; touch /home/ubuntu/.ssh/authorized_keys

RUN mkdir -p ~deploy/.ssh && \
    sh -c "cat /home/ubuntu/.ssh/authorized_keys >> ~deploy/.ssh/authorized_keys" && \
    chown -R deploy: ~deploy/.ssh && \
    chmod 700 ~deploy/.ssh && \
    sh -c "chmod 600 ~deploy/.ssh/*"

## Install rbenv

RUN apt-get install -y curl gnupg build-essential git-core libssl-dev libreadline-dev zlib1g-dev

USER deploy

RUN git clone https://github.com/sstephenson/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile && \
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile && \
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash

## Install ruby version

RUN . ~/.bash_profile && \
    rbenv install 2.2.2

USER root

## Tim loves vim
RUN apt-get install -y vim

## only needed for sqlite
RUN apt-get install -y libsqlite3-dev

## needed for rails, but really only on the build box
RUN apt-get install -y nodejs

## configure passenger

# enable passenger by uncommenting/replacing passenger_root and passenger_ruby
RUN sed -i 's|^.*# passenger_ruby .*|        passenger_ruby /home/deploy/.rbenv/shims/ruby;|' /etc/nginx/nginx.conf && \
    sed -i 's|^.*# passenger_root |        passenger_root |' /etc/nginx/nginx.conf

## create the file system
ADD config/etc.nginx.sites-enabled.default /etc/nginx/sites-enabled/default
RUN mkdir -p /var/www/tinge/current/public && \
    chown -R deploy:deploy /var/www/tinge

## Prepare the install

USER deploy

RUN . ~/.bash_profile && \
    rbenv shell 2.2.2 && \
    gem install bundler --no-rdoc --no-ri

## pull the code (we don't do this in production)
RUN . ~/.bash_profile && \
    rbenv shell 2.2.2 && \
    cd /var/www/tinge/current && \
    rm -rf ./* && \
    git clone https://github.com/tsabat/example_rails.git . && \
    bundle install && \
    RAILS_ENV=production bin/rake assets:precompile && \
    echo 'done!'

USER root
