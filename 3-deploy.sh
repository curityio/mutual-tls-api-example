#!/bin/bash

##########################################################################
# A script to deploy the Authorization Server, API Gateway and Example API
##########################################################################

#
# This just prevents accidental checkins of license files by Curity developers
#
cp hooks/pre-commit .git/hooks

#
# Check that a license file for the Curity Identity Server has been provided
#
if [ ! -f './docker/idsvr/license.json' ]; then
  echo "Please provide a license.json file in the docker/idsvr folder in order to deploy the system"
  exit 1
fi

#
# Check that certificates have been generated
#
if [ ! -f './certs/root.pem' ]; then
  echo "Please generate some certificates before deploying the system"
  exit 1
fi

#
# Spin up all Docker components
#
cd docker
docker compose up --force-recreate
if [ $? -ne 0 ]; then
  echo "Problem encountered running Docker components"
  exit 1
fi
