# Mutual TLS Secured API Code Example

[![Quality](https://img.shields.io/badge/quality-experiment-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

A code example to demonstrate Mutual TLS infrastructure and use of certificate bound access tokens.

## B2B APIs

Mutual TLS is commonly used for APIs between business partners, including in Open Banking setups:

![Sequence](images/sequence.png)

## Walkthrough

The [Mutual TLS API Code Example Article](https://curity.io/resources/learn/mutual-tls-api/) explains the technical behavior and setup.

## Quick Start

First create certificates for testing:

```bash
./1-create-certs.sh
```

Then build the code:

```bash
./2-build.sh
```

Then deploy the Mutual TLS endpoints:

```bash
./3-deploy.sh
```

Then authenticate via Mutual TLS and call the API over a Mutual TLS channel:

```bash
./4-run-client.sh
```

For troubleshooting view the logs by running one or more of the following commands:

```bash
./5-view-logs.sh api
./5-view-logs.sh identity-server
./5-view-logs.sh reverse-proxy
```

## Security Workflow

The code example enables the security workflow to be easily run on a development computer:

### Client Behavior

- The client authenticates using the OAuth Client Credentials Grant with a Client Certiticate credential
- The client then receives an opaque access token and sends it to the API, using Mutual TLS and the token

### Reverse Proxy and Mutual TLS Termination

- For OAuth requests the Mutual TLS verification is done by the Curity Identity Server
- For API requests the Mutual TLS verification is done by the reverse proxy

### Curity Identity Server

- A dedicated endpoint is used for Mutual TLS connections, which avoids impacting other clients
- Access tokens are issued with a `cnf` claim containing the SHA256 thumbprint of the client's certificate

### Certificate Bound Token Verification

- During API requests the reverse proxy introspects the opaque token from the client to get the token in JWT format
- The reverse proxy then verifies that the JWT's `cnf` claim matches the thumbprint of the request's client certificate

## Teardown

Once you're done testing out the solution run

```bash
./6-teardown.sh
```

to remove all the project's containers.

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
