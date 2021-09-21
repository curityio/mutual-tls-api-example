#!/bin/bash

####################################################################
# A script to create development certificates for Mutual TLS testing
####################################################################

cd certs
set -e

#
# Point to the OpenSSL configuration file for macOS or Windows
#
case "$(uname -s)" in

  Darwin)
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  MINGW64*)
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;
esac

#
# Certificate parameters
#
ROOT_CERT_FILE_PREFIX='root'
ROOT_CERT_DESCRIPTION='Curity Self Signed Root CA for Mutual TLS Testing'

CLIENT_CERT_NAME='demo-partner'
CLIENT_CERT_FILE_PREFIX='example.client'
CLIENT_CERT_PASSWORD='Password1'

TLS_CERT_FILE_PREFIX='example.tls'
TLS_CERT_PASSWORD='Password1'
TLS_CERT_NAME='*.example.com'

#
# Create a root certificate authority to simulate eIDAS
#
openssl genrsa -out $ROOT_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created Root CA key'

openssl req \
    -x509 \
    -new \
    -nodes \
    -key $ROOT_CERT_FILE_PREFIX.key \
    -out $ROOT_CERT_FILE_PREFIX.pem \
    -subj "/CN=$ROOT_CERT_DESCRIPTION" \
    -reqexts v3_req \
    -extensions v3_ca \
    -sha256 \
    -days 3650
echo '*** Successfully created Root CA'

#
# Create the client certificate that the example merchant will use
#
openssl genrsa -out $CLIENT_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created client key'

openssl req \
    -new \
    -key $CLIENT_CERT_FILE_PREFIX.key \
    -out $CLIENT_CERT_FILE_PREFIX.csr \
    -subj "/CN=$CLIENT_CERT_NAME"
echo '*** Successfully created client certificate signing request'

openssl x509 -req \
    -in $CLIENT_CERT_FILE_PREFIX.csr \
    -CA $ROOT_CERT_FILE_PREFIX.pem \
    -CAkey $ROOT_CERT_FILE_PREFIX.key \
    -CAcreateserial \
    -out $CLIENT_CERT_FILE_PREFIX.pem \
    -sha256 \
    -days 365 \
    -extfile client.ext
echo '*** Successfully created client certificate'

openssl pkcs12 \
    -export -inkey $CLIENT_CERT_FILE_PREFIX.key \
    -in $CLIENT_CERT_FILE_PREFIX.pem \
    -name $CLIENT_CERT_NAME \
    -out $CLIENT_CERT_FILE_PREFIX.p12 \
    -passout pass:$CLIENT_CERT_PASSWORD
echo '*** Successfully exported client certificate to a PKCS#12 file'

#
# Create the SSL certificate that back end components will use
#
openssl genrsa -out $TLS_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created TLS key'

openssl req \
    -new \
    -key $TLS_CERT_FILE_PREFIX.key \
    -out $TLS_CERT_FILE_PREFIX.csr \
    -subj "/CN=$TLS_CERT_NAME"
echo '*** Successfully created TLS certificate signing request'

openssl x509 -req \
    -in $TLS_CERT_FILE_PREFIX.csr \
    -CA $ROOT_CERT_FILE_PREFIX.pem \
    -CAkey $ROOT_CERT_FILE_PREFIX.key \
    -CAcreateserial \
    -out $TLS_CERT_FILE_PREFIX.pem \
    -sha256 \
    -days 365 \
    -extfile server.ext
echo '*** Successfully created TLS certificate'

openssl pkcs12 \
    -export -inkey $TLS_CERT_FILE_PREFIX.key \
    -in $TLS_CERT_FILE_PREFIX.pem \
    -name $TLS_CERT_NAME \
    -out $TLS_CERT_FILE_PREFIX.p12 \
    -passout pass:$TLS_CERT_PASSWORD
echo '*** Successfully exported TLS certificate to a PKCS#12 file'
