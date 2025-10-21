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
            try await provisionDatabase(vaultClient: vaultClient)
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

        func provisionDatabase(vaultClient: VaultClient) async throws {
            let databaseMountPath = "database"
            let databaseConnection = "pg_connection"
            let staticRoleName = "static_server_role"
            let dynamicRoleName = "dynamic_migrator_role"

            // Enable Database secret engine
            try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: databaseMountPath))
            print("Database secrets engine enabled at '\(databaseMountPath)'.")

            try await vaultClient.withDatabaseClient(mountPath: "database") { client in
                // Create connection between vault and a postgresql database
                try await client.createPostgresConnection(
                    configuration: .init(
                        connection: databaseConnection,
                        allowedRoles: [
                            staticRoleName,
                            dynamicRoleName
                        ],
                        connectionUrl: "postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable",
                        username: "vault_root",
                        password: "root_password"
                    )
                )

                // Create static role
                try await client.create(
                    staticRole: .postgres(
                        .init(
                            vaultRoleName: staticRoleName,
                            databaseUsername: "todos_user",
                            databaseConnectionName: databaseConnection,
                            rotation: .period(.seconds(3600*60*24*28)),
                            credentialType: .password
                        )
                    )
                )
                print("Static role '\(staticRoleName)' created.")

                // Create dynamic role
                try await client.create(
                    dynamicRole: .postgres(
                        .init(
                            vaultRoleName: dynamicRoleName,
                            databaseConnectionName: databaseConnection,
                            defaultTimeToLive: .seconds(120),
                            creationStatements: [
                                #"CREATE ROLE "{{name}}" WITH SUPERUSER LOGIN PASSWORD '{{password}}';"#
                            ],
                            credentialType: .password
                        )
                    )
                )
                print("Dynamic role '\(dynamicRoleName)' created.")
            }
        }
    }
}
