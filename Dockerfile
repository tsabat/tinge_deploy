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

RUN apt-get install -y curl gnupg build-essential git-core

USER deploy

RUN git clone https://github.com/sstephenson/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile && \
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile && \
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash

## Install ruby version


RUN . ~/.bash_profile && \
    rbenv install 2.2.2
