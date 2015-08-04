#!/bin/bash

set -ex

NOW=$(date +"%Y-%m-%d_%k-%M-%S")
./version.sh $NOW

if [ ! -d versions ]
then
  mkdir versions
fi

cd versions
mkdir -p $NOW/code
cp -r /var/www/tinge/versions/$NOW $NOW/code/$NOW
mkdir $NOW/scripts
cp -r ../scripts/* $NOW/scripts
echo $NOW > $NOW/version.txt

cp ../appspec.yml $NOW

aws deploy push \
  --application-name tinge_hello_world_application \
  --s3-location "s3://tinge-codedeploy/$NOW.zip" \
  --source $NOW \
  --region us-west-2
