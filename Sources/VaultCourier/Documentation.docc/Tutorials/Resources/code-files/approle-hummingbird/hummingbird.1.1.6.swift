import ArgumentParser
import struct Foundation.URL
import OpenAPIAsyncHTTPClient
import VaultCourier

@main
struct VaultAdmin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A sample vault-admin operations tool",
        subcommands: [
            Provision.self,
            AppRoleCredentials.self
        ]
    )
}

extension VaultAdmin {
    struct AppRoleCredentials: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "credentials",
            abstract: "Generates the approle credentials for the Todo server or migrator app."
        )
        @Argument var app: App

        @Option(name: .shortAndLong)
        var outputFile: String = "./approle_secret_id.txt"

        enum App: String, ExpressibleByArgument {
            case todo
            case migrator
        }

        func run() async throws {
            let vaultClient = VaultClient(
                configuration: .defaultHttp(),
                clientTransport: AsyncHTTPClientTransport()
            )
            try await vaultClient.login(method: .token("education"))

            try await generateSecretID(app, vaultClient: vaultClient)
        }

        func generateSecretID(_ app: App, vaultClient: VaultClient) async throws {
            let appRoleName = switch app {
                case .todo:
                    "server_app_role"
                case .migrator:
                    "migrator_app_role"
            }
            print("Generating Approle credentials for '\(app.rawValue)' app...")

            // Generate SecretID for the given app
            let tokenResponse = try await vaultClient.generateAppSecretId(capabilities: .init(roleName: appRoleName))
            let secretID: String = switch tokenResponse {
                case .wrapped(let wrappedResponse):
                    wrappedResponse.token
                case .secretId(let secretIdResponse):
                    secretIdResponse.secretID
            }
            try secretID.write(to: URL(filePath: self.outputFile), atomically: true, encoding: .utf8)
            print("SecretID successfully written to \(outputFile)")

            let roleIdResponse = try await vaultClient.appRoleID(name: appRoleName)
            print("\(app.rawValue) app roleID: \(roleIdResponse.roleId)")
        }
    }

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
            try await configureAppRole(vaultClient: vaultClient)
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

        func provisionDatabase(vaultClient: VaultClient) async throws {
            let databaseMountPath = "database"
            let databaseConnection = "pg_connection"
            let staticRoleName = "static_server_role"
            let dynamicRoleName = "dynamic_migrator_role"

            // Enable Database secret engine
            try await vaultClient.enableSecretEngine(mountConfig: .init(config.database.mount))
            print("Database secrets engine enabled at '\(config.database.mount.path)'.")

            try await vaultClient.withDatabaseClient(mountPath: config.database.mount.path) { client in
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
                try await client.create(staticRole: 
                    .postgres(
                        .init(
                            vaultRoleName: staticRoleName,
                            databaseUsername: "todos_user",
                            databaseConnectionName: databaseConnection,
                            rotation: .period(.seconds(3600*60*24*28)),
                            credentialType: .password
                        )
                    )
                )
                print("Static role '\(config.database.staticRole.vault_role_name)' created.")

                // Create dynamic role
                try await client.create(dynamicRole:
                    .postgres(
                        .init(
                            vaultRoleName: dynamicRoleName,
                            databaseConnectionName: databaseConnection,
                            defaultTTL: .seconds(120),
                            creationStatements: [
                                #"CREATE ROLE "{{name}}" WITH SUPERUSER LOGIN PASSWORD '{{password}}';"#
                            ],
                            credentialType: .password
                        )
                    )
                )
                print("Dynamic role '\(config.database.dynamicRole.name)' created.")
            }
        }

        func configureAppRole(vaultClient: VaultClient) async throws {
            // Enable AppRole authentication
            try await vaultClient.enableAuthMethod(configuration: .init(path: "approle", type: "approle"))
            print("AppRole Authentication enabled.")

            // Create server approle
            let todoAppRole = "server_app_role"
            try await vaultClient.createAppRole(.init(
                name: todoAppRole,
                secretIdTTL: .seconds(3600),
                tokenPolicies: ["todos"],
                tokenTTL: .seconds(3600),
                tokenType: .service)
            )
            print("AppRole '\(todoAppRole)' created.")

            // Create Migrator approle
            let migratorAppRole = "migrator_app_role"
            try await vaultClient.createAppRole(.init(
                name: migratorAppRole,
                secretIdTTL: .seconds(3600),
                tokenPolicies: ["migrator"],
                tokenTTL: .seconds(3600),
                tokenType: .batch)
            )
            print("AppRole '\(migratorAppRole)' created.")
        }
    }
}