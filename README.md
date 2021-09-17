# Mutual TLS Secured API Code Example

A Mutual TLS code example to demonstrate the setup and the use of sender constrained access tokens.

## Business Scenarios

This type of API is commonly used between business partners, and this can include Open Banking setups:

![Sequence](doc/sequence.png)

## Prerequisites

Some prerequisite setup is needed, including running a script to create some self signed certificates for testing.\
The [Financial Grade API Code Example](https://curity.io/resources/learn/financial-grade-api/) article explains these steps and provides a complete walkthrough.

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

### Client

The client authenticates using the OAuth Client Credentials Grant with a Client Certiticate credential.

### Authorization Server

The Curity Identity Server presents a Mutual TLS endpoint and issues tokens that include the client's public key.

### API Gateway

The API Gateway terminates Mutual TLS for API requests, then passes the certificate public key to the API.

### API

The API verifies that the certificate public key received matches the `cnf` claim in the JWT.

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
