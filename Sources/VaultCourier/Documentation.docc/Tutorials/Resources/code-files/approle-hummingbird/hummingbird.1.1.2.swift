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
}

extension VaultAdmin {
    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Provision vault policies, approles and sets the database secret mount."
        )

        func run() async throws {
            let vaultClient = VaultClient(
                configuration: .defaultHttp(),
                clientTransport: AsyncHTTPClientTransport()
            )
            try await vaultClient.login(method: .token("education"))

            try await updatePolicies(vaultClient: vaultClient)
        }

        func updatePolicies(vaultClient: VaultClient) async throws {
            let policies = [
                "todos": #"path \"database/static-creds/*\" { capabilities = [\"read\"] }"#,
                "migrator": #"path \"database/creds/*\" { capabilities = [\"read\"] }"#
            ]

            for (name, policy) in policies {
                try await vaultClient.createPolicy(hcl: .init(name: name, policy: policy))
                print("Policy '\(name)' written.")
            }
        }
    }
}
