#!/bin/bash

#
# A simple test client to show the HTTP requests for getting and sending a token with Mutual TLS
#

#
# Get full path of the parent folder of this script
#
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

IDENTITY_SERVER_BASE_URL=https://login.example.com/oauth/v2
API_BASE_URL=https://api.example.com/api
CLIENT_ID=partner-client
CLIENT_SECRET=Password1
CLIENT_CERT_PASSWORD=Password1
RESPONSE_FILE="$D/.test/response.txt"

mkdir -p "$D/.test"

#
# Act as the client to get an opaque access token using Mutual TLS
#
echo "Client is authenticating with the Identity Server via Mutual TLS ..."
HTTP_STATUS=$(curl -s -X POST "$IDENTITY_SERVER_BASE_URL/oauth-token-mutual-tls" \
--cert "$D/certs/example.client.p12":"$CLIENT_CERT_PASSWORD" \
--cert-type P12 \
--cacert "$D/certs/root.pem" \
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
echo "Client successfully authenticated and received an opaque access token"

#
#
# Act as the client sending the opaque access token to the API
#
echo "Client is creating a transaction at the API using Mutual TLS and the opaque access token ..."
HTTP_STATUS=$(curl -s -X POST "$API_BASE_URL/transactions" \
--cert "$D/certs/example.client.p12":"$CLIENT_CERT_PASSWORD" \
--cert-type P12 \
--cacert "$D/certs/root.pem" \
-H "Authorization: Bearer $OPAQUE_ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Client experienced a problem calling the example API: $HTTP_STATUS"
  exit
fi
JSON=$(tail -n 1 $RESPONSE_FILE)
echo "Client successfully created the API transaction using Mutual TLS"
