#!/bin/bash

######################################################################################
# A simple script to view logs for the reverse proxy container and view LUA processing
######################################################################################

if [ $# -ne 1 ] || [ $1 -eq "--help" ]; then
  echo "Usage: ./5-view-logs.sh [reverse-proxy | api | identity-server]" 1>&2
  exit 1
fi

SHORT_NAME="$1"

case "$SHORT_NAME" in
"reverse-proxy" | "api" | "identity-server")

  ;;
*)
  echo "Unknown name. Possible values are \"reverse-proxy\", \"api\", \"identity-server\"" 1>&2
  exit 1
;;
esac

export OPENRESTY_CONTAINER_ID=$(docker container ls --filter "label=com.docker.compose.service=$1" --filter "label=com.docker.compose.project=mutual-tls-api-example" --quiet)
echo "Showing logs for container $OPENRESTY_CONTAINER_ID"
docker logs -f $OPENRESTY_CONTAINER_ID
