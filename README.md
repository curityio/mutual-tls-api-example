# Financial Grade API Code Example

A Mutual TLS code example to demonstrate use of sender constrained access tokens

## Example Business Scenario

The example represents an Open Banking scenario that would use eIDAS certificates for mutual trust.\
The concepts are translated to a setup that can be easily run on a development computer.

![Sequence](doc/sequence.png)

## Prerequisites

TODO: Certificate creation, hosts file setup, license file, Java 8 and maven

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

## Components and Responsibilities

### Client

The client authenticates using a Client Certificate and a Mutual TLS connection to the Curity Identity Server.

### Authorization Server

The Curity Identity Server runs behind a reverse proxy and issues tokens when a trusted client certificate is presented.

### API Gateway

The API Gateway terminates Mutual TLS for API requests, then passes the certificate public key to the API in an HTTP header.

### API

The API verifies that the certificate public key matches the cnf claim in the JWT, then performs standard JWT validation.

## More Information

See the [Financial Grade API Code Example](https://curity.io/resources/learn/financial-grade-api/) article for a more complete walkthrough.\
Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
