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

VaultCourier can be used to retrieve the secrets that your application needs. This can be done using the API client itself or by reading a pkl configuration file with a `vault` or custom schema. In addition, Vault administrators can use the VaultCourier to provision and manage access to secrets. The latter includes the rotation of secrets. Check out the essentials section for concrete examples of usage

## Topics

### Essentials
- <doc:Checking-out-an-example-project>

### Tutorials

- <doc:tutorials/Vault-Courier>

### API
- <doc:VaultCourier>
