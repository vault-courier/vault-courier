# Checking out an example project

Check out a working example to learn how applications can start using a VaultCourier to leverage modern secret management

## Overview

The following examples show how to use and integrate a VaultCourier into different types of applications. When appropiate we will differentiate from an app and operations developer perspective.

Since this project is an API client of Hashicorp Vault and OpenBao, you need to have installed one of these tools for working with the examples. If you don't have any of these software, please visit [Hashicorp Vault installation](https://developer.hashicorp.com/vault/docs/install) or [OpenBao installation guides](https://openbao.org/docs/install/) for instructions.

> Important: Many of these examples have been deliberately simplified and are intended for illustrative purposes only. In particular, never run install vault server in dev mode in production.

## Getting started

Each of the following packages shows an end-to-end working example.

- write-secret-urlsession-example - A CLI client for writing a Key/Value secret using the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API as transport.
- read-secret-urlsession-example - A CLI client for reading a Key/Value secret using the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API as transport.
- write-secret-async-http-client-example - A CLI client for writing a Key/Value secret using the [AsyncHTTPClient](https://github.com/swift-server/async-http-client) API as transport.
- read-secret-async-http-client-example - A CLI client for reading a Key/Value secret using the [AsyncHTTPClient](https://github.com/swift-server/async-http-client) API as transport.

## Integrations

- TODO: postgres-static-role-example - A CLI client that creates a static role in a [Postgres](https://www.postgresql.org) database.
- TODO: postgres-dynamic-role-example - A CLI client that creates a dynamic role in a [Postgres](https://www.postgresql.org) database.
