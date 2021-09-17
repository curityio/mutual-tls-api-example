#!/bin/bash

##########################################################################
# A script to deploy the Authorization Server, API Gateway and Example API
##########################################################################

rm -rf .deploy 2>/dev/null
mkdir -p .deploy

#
# This just prevents accidental checkins of license files by Curity developers
#
cp hooks/pre-commit .git/hooks

#
# Download the phantom token plugin
#
cd .deploy
rm -rf kong-phantom-token-plugin
git clone https://github.com/curityio/kong-phantom-token-plugin
if [ $? -ne 0 ]; then
  echo "Problem encountered downloading the phantom token plugin"
  exit 1
fi

#
# Spin up all Docker components
#
cd ../docker
docker compose up --force-recreate
if [ $? -ne 0 ]; then
  echo "Problem encountered running Docker components"
  exit 1
fi
