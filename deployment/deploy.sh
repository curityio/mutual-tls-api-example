#!/bin/bash

##########################################################################
# A script to deploy the Authorization Server, API Gateway and Example API
##########################################################################

#
# This just prevents accidental checkins of license files by Curity developers
#
cp ../hooks/pre-commit ../.git/hooks

#
# Spin up Docker components
#
docker compose up --force-recreate