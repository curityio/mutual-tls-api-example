#!/bin/bash

##########################################################################
# A script to deploy the Authorization Server, API Gateway and Example API
# The script also automates the Mutual TLS certificate setup
##########################################################################

RESTCONF_BASE_URL='https://localhost:6749/admin/api/restconf/data'
ADMIN_USER='admin'
ADMIN_PASSWORD='Password1'
RUNTIME_TLS_CERT_NAME='Curity_Example_TLS_Cert'
PRIVATE_KEY_PASSWORD='Password1'

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
# Create environment variables for certificates
#
export CURITY_EXAMPLE_ROOT_CA=$(openssl base64 -in ./certs/root.pem | tr -d '\n')
export CURITY_EXAMPLE_TLS_KEY=$(openssl base64 -in ./certs/example.tls.p12 | tr -d '\n')

#
# Spin up all Docker components
#
echo "Deploying Docker system ..."
cd docker
docker compose up --detach --force-recreate --remove-orphans
if [ $? -ne 0 ]; then
  echo "Problem encountered running Docker components"
  exit 1
fi

#
# Wait for the admin endpoint to become available
#
echo "Waiting for the Curity Identity Server ..."
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ADMIN_USER:$ADMIN_PASSWORD" "$RESTCONF_BASE_URL?content=config")" != "200" ]; do 
  sleep 2s
done

#
# Update SSL keys and use the private key password to protect it in transit
#
echo "Updating certificates ..."
HTTP_STATUS=$(curl -k -s \
-X POST "$RESTCONF_BASE_URL/base:facilities/crypto/add-ssl-server-keystore" \
-u "$ADMIN_USER:$ADMIN_PASSWORD" \
-H 'Content-Type: application/yang-data+json' \
-d "{\"id\":\"$RUNTIME_TLS_CERT_NAME\",\"password\":\"$PRIVATE_KEY_PASSWORD\",\"keystore\":\"$CURITY_EXAMPLE_TLS_KEY\"}" \
-o /dev/null -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "Problem encountered updating the runtime SSL certificate: $HTTP_STATUS"
  exit 1
fi

#
# Provide a user prompt to run the test script
#
echo "System is ready for Mutual TLS connections ..."
