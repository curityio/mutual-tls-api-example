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
# Spin up all Docker components
#
cd docker
docker compose up --force-recreate
if [ $? -ne 0 ]; then
  echo "Problem encountered running Docker components"
  exit 1
fi
