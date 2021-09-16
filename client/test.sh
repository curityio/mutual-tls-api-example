#!/bin/bash

#
# A simple test client to show the HTTP requests for getting and sending a token with Mutual TLS
#

IDENTITY_SERVER_BASE_URL=https://login.example.com:8443/oauth/v2
CLIENT_ID=merchant-client
CLIENT_SECRET=Password1
INTROSPECT_CLIENT_ID=introspect-client
INTROSPECT_CLIENT_SECRET=Password1
RESPONSE_FILE=../.tmp/response.txt

#
# Act as the client to get an opaque access token using Mutual TLS
#
echo "Client is authenticating via Mutual TLS ..."
mkdir -p ../.tmp
HTTP_STATUS=$(curl -s -X POST "$IDENTITY_SERVER_BASE_URL/oauth-token" \
    --cert ../certs/example.client.pem \
    --key ../certs/example.client.key \
    --cacert ../certs/root.pem \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$CLIENT_ID" \
    -d "grant_type=client_credentials" \
    -d "scope=transactions" \
    -o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Client experienced a problem authenticating via Client Credentials with Mutual TLS: $HTTP_STATUS"
  exit
fi
JSON=$(tail -n 1 $RESPONSE_FILE) 
OPAQUE_ACCESS_TOKEN=$(jq -r .access_token <<< "$JSON")
echo "Client successfully authenticated and received access token: $OPAQUE_ACCESS_TOKEN"

#
# Act as the gateway by introspecting the JWT access token
#
echo "API gateway is introspecting the access token received over a Mutual TLS channel ..."
HTTP_STATUS=$(curl -s -X POST "$IDENTITY_SERVER_BASE_URL/oauth-introspect" \
    -u "$INTROSPECT_CLIENT_ID:$INTROSPECT_CLIENT_SECRET" \
    -H "Accept: application/jwt" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "token=$OPAQUE_ACCESS_TOKEN" \
    -o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** API gateway experienced a problem introspecting the opaque access token"
  exit
fi
JWT_ACCESS_TOKEN=$(tail -n 1 $RESPONSE_FILE)
echo "API gateway successfully retrieved JWT access token: $JWT_ACCESS_TOKEN"

#
# Act as the API receiving a JWT
#
JWT_PAYLOAD=$(jq -R 'split(".") | .[1] | @base64d | fromjson' <<< "$JWT_ACCESS_TOKEN")
echo "API received JWT with payload ..."
echo $JWT_PAYLOAD | jq

#
# Act as the API by receiving a JWT
#
echo "API received CNF claim to identify the client certificate ..."
CNF_CLAIM=$(jq -r .cnf <<< "$JWT_PAYLOAD")
echo $CNF_CLAIM | jq

#
# OpenSSL debugging commands
#
#openssl s_client -showcerts -connect login.example.com:8443
#openssl s_client -CAfile ../../certs/root.pem -showcerts -connect login.example.com:8443
