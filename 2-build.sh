#!/bin/bash

########################################################################
# A script to build resources into Docker containers ready for deploying
########################################################################

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

cd ../docker/reverse-proxy
rm -rf .deploy
mkdir .deploy
cd .deploy

#
# Download reverse proxy plugins
#
git clone https://github.com/curityio/lua-nginx-phantom-token-plugin
if [ $? -ne 0 ]; then
  echo "Problem encountered downloading the phantom token plugin"
  exit 1
fi
git clone https://github.com/curityio/sender-constrained-token-plugin
if [ $? -ne 0 ]; then
  echo "Problem encountered downloading the sender constrained token plugin"
  exit 1
fi
cd ..

#
# Build the customized NGINX Docker Container with plugins
#
docker build -f ./Dockerfile -t custom_openresty:1.19.3.1-8-bionic .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Custom NGINX docker container'
  exit
fi