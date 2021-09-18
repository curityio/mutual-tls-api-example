#!/bin/bash

#
# A simple test client to show the HTTP requests for getting and sending a token with Mutual TLS
#

IDENTITY_SERVER_BASE_URL=https://login.example.com/oauth/v2
API_BASE_URL=https://api.example.com:444/api
CLIENT_ID=partner-client
CLIENT_SECRET=Password1
RESPONSE_FILE=../.test/response.txt

mkdir -p ../.test

#
# Act as the client to get an opaque access token using Mutual TLS
#
echo "Client is authenticating with the Identity Server via Mutual TLS ..."
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
# Act as the client sending the JWT to the API
#
echo "Client is calling the example API over Mutual TLS ..."
HTTP_STATUS=$(curl -s -X POST "$API_BASE_URL/transactions" \
    --cert ../certs/example.client.pem \
    --key ../certs/example.client.key \
    --cacert ../certs/root.pem \
    -H "Authorization: Bearer $OPAQUE_ACCESS_TOKEN" \
    -H "x-example-client-public-key: abc123" \
    -H "Content-Type: application/json" \
    -o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Client experienced a problem calling the example API: $HTTP_STATUS"
  exit
fi
echo "Client successfully called the API"