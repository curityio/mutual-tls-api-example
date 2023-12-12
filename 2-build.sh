#!/bin/bash

########################################################################
# A script to build resources into Docker containers ready for deploying
########################################################################

#
# Get full path of the parent folder of this script
#
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)


#
# Get API dependencies
#
cd "$D/api"
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

cd ../docker/reverse-proxy

#
# Download reverse proxy plugins
#
git submodule update --init --remote --rebase

#
# Build the customized NGINX Docker Container with plugins
#
docker build -f ./Dockerfile -t custom_openresty:1.21.4.3-2-bionic .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Custom NGINX docker container'
  exit
fi
