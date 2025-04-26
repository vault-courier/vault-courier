#  VaultCourier

@Metadata {
    @TechnologyRoot()
}

Swift client for interacting with Hashicorp Vault and OpenBao.

## Overview

[Hashicorp Vault](https://developer.hashicorp.com/vault) and [OpenBao](https://openbao.org) are both tools for securely storing, auditing and managing access to secrets, such as API tokens, database credentials, and certificates. VaultCourier is a swift package that can interact with Hashicorp Vault and OpenBao to retrieve and provision secrets. It is built with [swift-openapi](https://github.com/apple/swift-openapi-generator) and [pkl](https://pkl-lang.org).

### Features

- Arbitrary storage of Key/Value secrets
- Generation of static and dynamic credentials; database engine with PostgreSQL support.
- AppRole Authentication
- Token Authentication
- Pkl Resource Reader.

## Usage

VaultCourier can be used to retrieve the secrets that your App needs. This can be done with the API client itself or via reading a pkl configuration file. In addition, Vault administrators can use the VaultCourier to provision and manage secrets access. The later includes rotation of secrets. Below you can find example code, or you can follow one of the working with a swift vault client tutorials.

## Topics

### Essentials
- <doc:Checking-out-an-example-project>

