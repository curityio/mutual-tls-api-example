# Financial Grade API Code Example

A Mutual TLS code example to demonstrate use of sender constrained access tokens

## Example Business Scenario

The example represents an Open Banking scenario that would use eIDAS certificates for mutual trust.\
The concepts are translated to a setup that can run on a development computer.

![Sequence](doc/sequence.png)

## Client

The client authenticates using a Client Certificate over a Mutual TLS channel to the Curity Identity Server.

## Authorization Server

The Curity Identity Server runs behind a reverse proxy and issues tokens based on a trusted client certificate.

## API Gateway

This is used to verify Mutual TLS for API requests, then pass the cnf claim to the API in a custom header.\
A small LUA plugin is used to perform this logic.

## API

The API receives and verifies the cnf claim in addition to performing its standard JWT validation.