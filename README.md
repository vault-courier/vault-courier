
## VaultCourier

Swift client for interacting with Hashicorp Vault and OpenBao.

[Hashicorp Vault](https://developer.hashicorp.com/vault) and [OpenBao](https://openbao.org) are both tools for securely storing, auditing and managing access to secrets, such as API tokens, database credentials, and certificates. VaultCourier is a swift package that can interact with Hashicorp Vault and OpenBao to retrieve and provision secrets. It is built with [swift-openapi](https://github.com/apple/swift-openapi-generator) and [pkl](https://pkl-lang.org).

### Features

- Arbitrary storage of Key/Value secrets
- Generation of static and dynamic credentials; Database Engine with PostgreSQL support.
- AppRole Authentication
- Token Authentication
- Pkl Resource Reader.

## Documentation

You can find reference documentation and user guides for VaultCourier here. The [vault-courier-examples](https://github.com/vault-courier/vault-courier-examples) repository has a number of examples of different uses of the library.

## Security

This library is currently under-development. Please try it out and give us feedback! Please do not use it in production.
If you believe you have identified a vulnerability in VaultCourier, please responsibly disclose by contacting us at contact@beamsplitter.co.

## License

VaultCourier is available under the [Apache 2.0 license](LICENSE).
