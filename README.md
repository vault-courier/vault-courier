
![Vault Courier](.readme-images/vault-courier-banner.png)

**Swift client for interacting with Hashicorp Vault and OpenBao.**

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvault-courier%2Fvault-courier%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/vault-courier/vault-courier)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvault-courier%2Fvault-courier%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/vault-courier/vault-courier)

[Hashicorp Vault](https://developer.hashicorp.com/vault) and [OpenBao](https://openbao.org) are both tools for securely storing, auditing and managing access to secrets, such as API tokens, database credentials, and certificates. VaultCourier is a [Swift](https://www.swift.org) package that can interact with Hashicorp Vault and OpenBao to retrieve and provision secrets. It is built with [swift-openapi](https://github.com/apple/swift-openapi-generator) and [pkl](https://pkl-lang.org).

### Features

- Arbitrary storage of Key/Value secrets (KV-v2)
- Manage third-party secrets: generate and revoke on-demand credentials for database systems, like PostgreSQL and Valkey.
- AppRole Authentication
- Token Authentication
- Pkl Resource Reader (Enabled with PackageTrait `PklSupport`).

## Usage

Here is a simple example of reading and writing your first secret! 
First run a Vault in dev mode with

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=learn-vault' hashicorp/vault:latest)
```

or with OpenBao

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'BAO_DEV_ROOT_TOKEN_ID=education' openbao/openbao:latest)
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

For a more realistic example that illustrates many important Vault concepts, see the tutorials and examples in the documentation.

### Package Traits

Vault has many secret engines and authentication methods that need to be enabled before they can be used. Similarly, in VaultCourier's functionality can be extended by enabling the respective Package traits. Currently we support the following:

To enable an additional trait on the package, update the package dependency:

```diff
.package(
    url: "https://github.com/vault-courier/vault-courier",
    .upToNextMinor(from: "0.3.0"),
+   traits: [.defaults, "OtherFeatureSupport"]
)
```

Available Package traits:
- `PostgresPluginSupport` (default): Enable support for Vault-PostgreSQL database plugin HTTP API. Plugin available in Vault and OpenBao. This trait enables `DatabaseEngineSupport`.
- `DatabaseEngineSupport` (default): Enable support for database engine clients. 
- `AppRoleSupport` (default): Enable AppRole authentication.
- `MockSupport` (default). Provides a mock client transport for unit testing and development, and adds Encodable conformance to certain Vault response types. 
- `ValkeyPluginSupport` (Opt-in): Enable support for OpenBao-Valkey database plugin HTTP API. This plugin is only available in OpenBao.
- `PklSupport` (experimental): Enable [Pkl](https://pkl-lang.org) Resource reader implementations that can read Vault secrets directly from pkl files.
- `ConfigProviderSupport` (experimental): Enable a Vault configuration provider. This trait provides a `swift-configuration` [ConfigProvider](https://swiftpackageindex.com/apple/swift-configuration/main/documentation/configuration/configprovider) implementation that can fetch Vault secrets.

### API Handlers

The Vault API is covered by sub-clients that specialize in a particular secret engine, authentication method or internal system features. These sub-clients are accessible via handler-methods. For example:

```swift
let configuration = PostgresConnectionConfig(connection: "pg-vault")
try await withDatabaseClient(mountPath: "database_eu_central") { client in
    try await client.createPostgresConnection(configuration: configuration)
    try await client.rotateRoot(connection: configuration.connection)
}
```

These types of handler methods are useful for Vault operators when multiple calls are going to be made to the same group of endpoints, or when functions need to be scoped to a particular mount. Application owners will rarely use these handlers, as they simply consume the secrets and the default functionality can be accessed directly from the VaultClient.

The opt-in Vault API is only accessible via an API handler method.


## Documentation

You can find reference documentation and user guides for VaultCourier [here](https://swiftpackageindex.com/vault-courier/vault-courier/main/documentation/vault-courier). The [vault-courier-examples](https://github.com/vault-courier/vault-courier-examples) repository has a number of examples of different uses of the library.

## Security

This library is currently under-development, so we recommend using `.upToNextMinor` in your Package.swift when depending on `vault-courier`. It's likely we'll have breaking changes between minors pre-1.0. Please try it out and give us feedback! Please do not use it in production.
If you believe you have identified a vulnerability in VaultCourier or any of its related repositories please do not post this in a public forum, do not create a GitHub Issue. Instead please responsibly disclose by contacting us at contact@beamsplitter.co.

## License

VaultCourier is available under the [Apache 2.0 license](LICENSE.txt).

## Acknowledgement

We'd like to give a special thanks to Anastasiya Mudrak for helping us digitize our first logo.
