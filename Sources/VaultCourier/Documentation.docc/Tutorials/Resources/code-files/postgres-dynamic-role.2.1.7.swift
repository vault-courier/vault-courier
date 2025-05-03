// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import OpenAPIAsyncHTTPClient
import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

@main
struct VaultDynamicRole: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()

        try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: enginePath))
        print("Database secret engine enabled at \(enginePath)")

        let config = Self.postgresConnectionConfiguration(connectionName)
        try await vaultClient.databaseConnection(configuration: config, enginePath: enginePath)
        print("""
        Success! Data written to: \(enginePath)/config/\(connectionName)
        """)

        let connection = try await vaultClient.databaseConnection(name: connectionName, enginePath: enginePath)
        print(connection)
    }

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

    static func postgresConnectionConfiguration(_ name: String) -> PostgresConnectionConfiguration {
        let host = "127.0.0.1"
        let port = 5432
        let databaseName = "postgres"
        let sslMode = "disable"
        let connectionURL = "postgresql://{{username}}:{{password}}@\(host):\(port)/\(databaseName)?sslmode=\(sslMode)"
        let vaultUsername = "vault_root"
        let vaultPassword = "root_password"
        let config = PostgresConnectionConfiguration(connection: name,
                                                     pluginName: "postgresql-database-plugin",
                                                     allowedRoles: ["dynamic_role", "static_role"],
                                                     connectionUrl: connectionURL,
                                                     username: vaultUsername,
                                                     password: vaultPassword,
                                                     passwordAuthentication: "scram-sha-256")
        return config
    }
}

extension DatabaseConnectionResponse: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
                allowed_roles: \(allowedRoles)
                connection_url: \(connectionURL?.debugDescription.removingPercentEncoding ?? "<n/a>")
                connection_username: \(username)
                password_authentication: \(authMethod)
                plugin_name: \(plugin?.name ?? "<n/a>")
                """
    }
}
