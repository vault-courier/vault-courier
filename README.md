
## VaultCourier

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvault-courier%2Fvault-courier%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/vault-courier/vault-courier)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvault-courier%2Fvault-courier%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/vault-courier/vault-courier)

Swift client for interacting with Hashicorp Vault and OpenBao.

[Hashicorp Vault](https://developer.hashicorp.com/vault) and [OpenBao](https://openbao.org) are both tools for securely storing, auditing and managing access to secrets, such as API tokens, database credentials, and certificates. VaultCourier is a [swift](https://www.swift.org) package that can interact with Hashicorp Vault and OpenBao to retrieve and provision secrets. It is built with [swift-openapi](https://github.com/apple/swift-openapi-generator) and [pkl](https://pkl-lang.org).

### Features

- Arbitrary storage of Key/Value secrets (KV-v2)
- Generation of static and dynamic credentials; database engine with PostgreSQL support.
- AppRole Authentication
- Token Authentication
- Pkl Resource Reader (Enabled with PackageTrait "Pkl").

## Documentation

You can find reference documentation and user guides for VaultCourier [here](https://swiftpackageindex.com/vault-courier/vault-courier/main/documentation/vault-courier). The [vault-courier-examples](https://github.com/vault-courier/vault-courier-examples) repository has a number of examples of different uses of the library.

## Security

This library is currently under-development. Please try it out and give us feedback! Please do not use it in production.
If you believe you have identified a vulnerability in VaultCourier or any of its related repositories please do not post this in a public forum, do not create a GitHub Issue. Instead please responsibly disclose by contacting us at contact@beamsplitter.co.

## License

VaultCourier is available under the [Apache 2.0 license](LICENSE.txt).
