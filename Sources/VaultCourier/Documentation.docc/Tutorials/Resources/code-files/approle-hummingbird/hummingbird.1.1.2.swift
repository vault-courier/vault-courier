import ArgumentParser
import struct Foundation.URL
import OpenAPIAsyncHTTPClient
import VaultCourier

@main
struct VaultAdmin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A sample vault-admin operations tool",
        subcommands: [
            Provision.self
        ]
    )
    static func makeVaultClient() throws -> VaultClient {
        let vaultURL = URL(string: "http://127.0.0.1:8200/v1")!
        let config = VaultClient.Configuration(apiURL: vaultURL)

        let client = Client(
            serverURL: vaultURL,
            transport: AsyncHTTPClientTransport()
        )

        return VaultClient(
            configuration: config,
            client: client,
            authentication: .token("education")
        )
    }
}

extension VaultAdmin {
    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Provision vault policies, approles and sets the database secret mount."
        )

        func run() async throws {
            let vaultClient = try makeVaultClient()
            try await vaultClient.authenticate()

            try await updatePolicies(vaultClient: vaultClient)
        }

        func updatePolicies(vaultClient: VaultClient) async throws {
            let policies = [
                "todos": #"path \"database/static-creds/*\" { capabilities = [\"read\"] }"#,
                "migrator": #"path \"database/creds/*\" { capabilities = [\"read\"] }"#
            ]

            for (name, policy) in policies {
                try await vaultClient.createPolicy(name: name, hclPolicy: policy)
                print("Policy '\(name)' written.")
            }
        }
    }
}