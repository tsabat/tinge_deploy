#!/bin/bash

set -ex

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
    -g|--group)
    GROUP="$2"
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
echo GROUP     = "${GROUP}"

if [ -z "$APP" ]; then
  echo "app is required!"
  EXIT=true
fi

if [ -z "$REPO" ]; then
  echo "repo is required!"
  EXIT=true
fi

if [ -z "$GROUP" ]; then
  echo "group is required!"
  EXIT=true
fi

if [[ "$EXIT" == true ]]; then
  exit 1
fi

# this is just nice, adding a random word to the revision name
# so we can view it easily in the listing
WORD=$(shuf -n1  /usr/share/dict/words | sed s/\'s//g |  awk '{print toupper($0)}')
NOW=$(date +"%Y-%m-%d_%k-%M-%S")
NOW="$NOW-$WORD"

# the version script creates the symlink structure
# that phusion passenger understands
./version.sh -a $APP -r $REPO -n $NOW

# then we create a versions folder of our own for the
# bundle we send to s3
if [ ! -d versions ]
then
  mkdir versions
fi

######################################################################
# let's build the bundle structure, which looks like the diagram below
######################################################################
#
# NOTE:
# * The date 2015-08-06_13_03_28 is the result of the $NOW variable
# * The the version.txt also contains the $NOW value
# * the appspec.yml is defined here: http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html
# * the scripts dir contains the lifecycle hooks defined in the appspec
# * the code => $NOW folder contains the ruby code
#
# └── 2015-08-06_13-03-28
#    ├── appspec.yml
#    ├── code
#    │   └── 2015-08-06_13-03-28
#    ├── scripts
#    │   ├── after_install.sh
#    │   └── application_stop.sh
#    └── version.txt

cd versions
mkdir -p $NOW/code
cp -r /var/www/tinge/versions/$NOW $NOW/code/$NOW
mkdir $NOW/scripts
cp -r ../scripts/* $NOW/scripts
echo $NOW > $NOW/version.txt

cp ../appspec.yml $NOW

#####################################################
# now that the bundle is built, we'll send it to the
# `aws deploy push` command.  The command itself takes care
# of the zipping and creates a 'revision' in codedeploy
#####################################################
RSLT=$(aws deploy push \
  --application-name tinge_hello_world_application \
  --s3-location "s3://tinge-codedeploy/$NOW.zip" \
  --source $NOW \
  --region us-west-2)

#################################################
# the result of above command is stored in $RSLT
# and looks like this:
################################################

# To deploy with this revision, run:
# aws deploy create-deployment --application-name tinge_hello_world_application --s3-location bucket=tinge-codedeploy,key=2015-08-05_23-37-29.zip,bundleType=zip,eTag="1d45984af648f8f9156d42033db7b626-11" --deployment-group-name <deployment-group-name> --deployment-config-name <deployment-config-name> --description <description>

##################################################
# below we are trying to get at the bucket and etag info
# which we pass to the aws deploy create-deployment command
####################################################

# drop everything before the --s3-location
# this uses param expansion, which you can read about here
# http://stackoverflow.com/a/19482947/182484)
RSLT=$(echo ${RSLT##*--s3-location})
# split on the space and grab first value
RSLT=$(echo $RSLT | cut -d ' ' -f 1)

########################################################
# this is the real call, which makes a deployment for you
#########################################################
aws deploy create-deployment \
  --application-name tinge_hello_world_application \
  --s3-location $RSLT \
  --deployment-group-name tinge_hello_world_as_group \
  --region us-west-2 \
  --description 'super-rad application'
