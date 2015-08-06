#!/bin/bash

set -ex

################################
# Get the values passed in
################################

# TODO: make these required instead of default

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -a|--application)
    APP="$2"
    shift # past argument
    ;;
    -r|--repo)
    REPO="$2"
    shift # past argument
    ;;
    -n|--now)
    NOW="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done
echo APP       = "${APP}"
echo REPO      = "${REPO}"
echo NOW       = "${$NOW}"

if [ -z "$APP" ]; then
  echo "app is required!"
  EXIT=true
fi

if [ -z "$REPO" ]; then
  echo "repo is required!"
  EXIT=true
fi

if [ -z "$NOW" ]; then
  echo "now is required!"
  EXIT=true
fi

if [[ "$EXIT" == true ]]; then
  exit 1
fi

REPO_DIR="repo_$APP"

sudo -i -u deploy bash <<HERE
set -ex

. ~/.bash_profile
rbenv shell 2.2.2
cd /var/www/tinge

if [ ! -d $REPO_DIR ]
then
  git clone $REPO $REPO_DIR
fi

cd $REPO_DIR
git pull origin master
bundle install --without test development --path vendor
RAILS_ENV=production bin/rake assets:precompile

cd ..
cp -r $REPO_DIR versions/$NOW
rm -rf versions/$NOW/.git
ln -snf /var/www/tinge/versions/$NOW /var/www/tinge/current
HERE
