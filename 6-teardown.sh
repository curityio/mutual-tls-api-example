#!/bin/bash

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "Removing Docker components"
cd "$D/docker"

docker compose --project-name mutual-tls-api-example down

if [ $? -ne 0 ]; then
  echo "Problem encountered removing Docker components"
  exit 1
fi

echo "Successfully removed project"
