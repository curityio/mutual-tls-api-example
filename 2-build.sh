#!/bin/bash

############################################################################
# A script to build the API code into a Docker container ready for deploying
############################################################################

#
# Get API dependencies
#
cd api
rm -rf node_modules
npm install
if [ $? -ne 0 ]; then
  echo "Problem encountered downloading API dependencies"
  exit 1
fi

#
# Build API code
#
npm run build
if [ $? -ne 0 ]; then
  echo "Problem encountered building API code"
  exit 1
fi

#
# Build the API Docker Container
#
docker build -f ./Dockerfile -t mutual-tls-api:1.0.0 .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the API docker container'
  exit
fi

#
# Build the customized NGINX Docker Container and its plugin
#
cd ../docker/reverse-proxy
docker build -f ./Dockerfile -t custom_openresty:1.19.3.1-8-bionic .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Custom NGINX docker container'
  exit
fi