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
    struct AppRoleCredentials: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "credentials",
            abstract: "Generates the approle credentials for the Todo server or migrator app."
        )
        @Argument var app: App

        /// Path to pkl file with app configuration
        @Argument var config: String

        @Option(name: .shortAndLong)
        var outputFile: String = "./approle_secret_id.txt"

        enum App: String, ExpressibleByArgument {
            case todo
            case migrator
        }

        func run() async throws {
            let vaultClient = try makeVaultClient()
            try await vaultClient.authenticate()

            let vaultConfig = try await VaultAdminConfig.loadFrom(source: .path(config))

            try await generateSecretID(app, config: vaultConfig, vaultClient: vaultClient)
        }

        func generateSecretID(_ app: App, config: VaultAdminConfig.Module, vaultClient: VaultClient) async throws {
            guard let appRole = config.authMethod.appRoles[app.rawValue] else {
                throw VaultOperationsError.missingApproleConfiguration("Missing '\(app.rawValue)' AppRole Config in pkl file")
            }
            print("Generating Approle credentials for '\(app.rawValue)' app...")

            // Generate SecretID for the given app
            let tokenResponse = try await vaultClient.generateAppSecretId(
                capabilities: .init(
                    appRole.tokenConfig
                )
            )
            let secretID: String = switch tokenResponse {
                case .wrapped(let wrappedResponse):
                    wrappedResponse.token
                case .secretId(let secretIdResponse):
                    secretIdResponse.secretID
            }
            try secretID.write(to: URL(filePath: self.outputFile), atomically: true, encoding: .utf8)
            print("SecretID successfully written to \(outputFile)")

            let roleIdResponse = try await vaultClient.appRoleID(name: appRole.properties.role_name)
            print("'\(app.rawValue)' app roleID: \(roleIdResponse.roleId)")
        }
    }

    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Provision vault policies, approles and sets the database secret mount."
        )

        /// Path to pkl file with app configuration
        @Argument var config: String

        func run() async throws {
            let vaultClient = try makeVaultClient()
            try await vaultClient.authenticate()

            let config = try await VaultAdminConfig.loadFrom(source: .path(config))

            try await updatePolicies(config: config, vaultClient: vaultClient)
            try await provisionDatabase(config: config, vaultClient: vaultClient)
            try await configureAppRole(config: config, vaultClient: vaultClient)
        }

        func updatePolicies(config: VaultAdminConfig.Module, vaultClient: VaultClient) async throws {
            for policy in config.policies {
                try await vaultClient.createPolicy(name: policy.name, hclPolicy: policy.payload)
                print("Policy '\(policy.name)' written.")
            }
        }

        func provisionDatabase(config: VaultAdminConfig.Module, vaultClient: VaultClient) async throws {
            // Enable Database secret engine
            try await vaultClient.enableSecretEngine(mountConfig: .init(config.database.mount))
            print("Database secrets engine enabled at '\(config.database.mount.path)'.")

            // Create connection between vault and a postgresql database
            try await vaultClient.databaseConnection(
                configuration: .init(config.database.connection),
                enginePath: config.database.mount.path
            )

            // Create static role
            try await vaultClient.create(
                staticRole: try config.database.staticRole.create,
                enginePath: config.database.mount.path
            )
            print("Static role '\(config.database.staticRole.vault_role_name)' created.")

            // Create dynamic role
            try await vaultClient.create(
                dynamicRole: .init(config.database.dynamicRole),
                enginePath: config.database.mount.path
            )
            print("Dynamic role '\(config.database.dynamicRole.name)' created.")
        }

        func configureAppRole(config: VaultAdminConfig.Module, vaultClient: VaultClient) async throws {
            // Enable AppRole authentication
            try await vaultClient.enableAuthMethod(configuration: .init(config.authMethod.config))
            print("AppRole Authentication enabled.")


            for appRole in config.authMethod.appRoles.values {
                try await vaultClient.createAppRole(.init(appRole.properties))
                print("AppRole '\(appRole.properties.role_name)' created.")
            }
        }
    }
}