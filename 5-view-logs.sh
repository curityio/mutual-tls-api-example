#!/bin/bash

######################################################################################
# A simple script to view logs for the reverse proxy container and view LUA processing
######################################################################################

export OPENRESTY_CONTAINER_ID=$(docker container ls | grep reverse-proxy | awk '{print $1}')
docker logs -f $OPENRESTY_CONTAINER_ID
