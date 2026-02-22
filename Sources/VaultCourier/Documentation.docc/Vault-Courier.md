#  VaultCourier

@Metadata {
    @TechnologyRoot()
}

Swift client for interacting with Hashicorp Vault and OpenBao.

## Overview

[Hashicorp Vault](https://developer.hashicorp.com/vault) and [OpenBao](https://openbao.org) are both tools for securely storing, auditing and managing access to secrets, such as API tokens, database credentials, and certificates. VaultCourier is a swift package that can interact with Hashicorp Vault and OpenBao to retrieve and provision secrets. It is built with [swift-openapi](https://github.com/apple/swift-openapi-generator) and [pkl](https://pkl-lang.org).

### Features

- Arbitrary storage of Key/Value secrets (KV-v2)
- Manage third-party secrets: generate and revoke on-demand credentials for database systems, like PostgreSQL and Valkey
- Cryptography as a Service (CaaS) via Transit secret engine
- AppRole Authentication
- Token Authentication
- Namespaces: manage isolated secrets from different deployment environments, applications, or teams within a single vault instance. 
- Tracing support
- Pkl Resource Reader (Enabled with PackageTrait `PklSupport`)

## Usage

VaultCourier can be used to retrieve the secrets that your application needs. This can be done using the API client itself or by reading a pkl configuration file. In addition, Vault administrators can use VaultCourier to provision and manage access to secrets. The latter includes the rotation of secrets.

Here is a simple example of reading and writing your first secret! 
First run a Vault in dev mode with

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=learn-vault' hashicorp/vault:latest)
```

or with OpenBao

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'BAO_DEV_ROOT_TOKEN_ID=learn-vault' openbao/openbao:latest)
```

then authenticate, write and read the secret.

```swift
import VaultCourier
import OpenAPIAsyncHTTPClient
import Foundation

let client = VaultClient(configuration: .defaultHttp(),
                         clientTransport: AsyncHTTPClientTransport())

// Authenticate
try await client.login(method: .token("learn-vault"))

// Write a secret
let keyToSecret = "my-secret-password"
struct Secret: Codable {
    let apiKey: String
}
try await client.writeKeyValue(mountPath: "secret",
                               secret: Secret(apiKey: "secret_api_key"),
                               key: keyToSecret)

print("Secret written successfully")

// Read a Secret
let secret: Secret = try await client.readKeyValueSecret(mountPath: "secret", key: keyToSecret)

print("Access Granted! API Key: \(secret.apiKey)")
```

To stop the Vault server run:

```sh
docker stop "${container_id}" > /dev/null
```

Check out the essentials section for concrete examples of usage.

## Topics

### Essentials
- <doc:Checking-out-an-example-project>

### Tutorials

- <doc:tutorials/Vault-Courier>

### API
- <doc:VaultCourier>
