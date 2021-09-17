# Mutual TLS Secured API Code Example

A Mutual TLS code example to demonstrate the setup and the use of sender constrained access tokens.

## B2B Scenarios

This type of API is commonly used between business partners, and this can include Open Banking setups:

![Sequence](doc/sequence.png)

## Prerequisites

Some prerequisite setup is needed, including running a script to create some self signed certificates for testing.\
The [Mutual TLS API Code Example Article](https://curity.io/resources/learn/mutual-tls-api/) explains these steps and provides a complete walkthrough.

## Quick Start

First build the code:

```bash
cd api
./build.sh
```

Then deploy the infrastructure, including Mutual TLS endpoints:

```bash
cd deployment
./deploy.sh
```

Then authenticate via Mutual TLS and call the API over a Mutual TLS channel:

```bash
cd client
./test.sh
```

## Security Workflow

The code example enables the below steps to be easily run on a development computer:

### Client Authentication

The client authenticates using the OAuth Client Credentials Grant with a Client Certiticate credential:

```bash
curl -s -X POST "https://login.example/com/oauth-token" \
    --cert ./certs/example.client.pem \
    --key ./certs/example.client.key \
    --cacert ./certs/root.pem \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=partner-client" \
    -d "grant_type=client_credentials" \
    -d "scope=transactions
```

### Client API Requests

The client then receives an opaque access token and sends it to the API, using Mutual TLS and the token: 

```bash
curl -s -X POST "https://api.example.com/api/transactions" \
    --cert ../certs/example.client.pem \
    --key ../certs/example.client.key \
    --cacert ../certs/root.pem \
    -H "Authorization: Bearer 3e138be5-e9ed-4895-9058-73a5ab649f66" \
    -H "Content-Type: application/json"
```

### API Gateway

The API Gateway deals with Mutual TLS requests differently for these types of request:

- OAuth requests are sent straight through to the Identity Server, where Mutual TLS is terminated
- API requests are terminated at the gateway, then the certificate public key is passed to the API

### Curity Identity Server

A dedicated port is provided for Mutual TLS connections, which avoids impacting other apps.\
Access tokens include a `cnf` claim containing the SHA256 certificate thumbprint of the client's certificate.

### API

APIs simply need to verify the client certificate thumbprint in the JWT matches that of the calling client:

```json
cnf:
{
"x5t#S256": "aEHDMMqTn73h-ybp-30KNG6aYeWCGjVgKO7WIBgB85Y"
}
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
