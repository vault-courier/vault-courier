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
    var enginePath: String = "sql_database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()
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
                                                     allowedRoles: ["read_only"],
                                                     connectionUrl: connectionURL,
                                                     username: vaultUsername,
                                                     password: vaultPassword,
                                                     passwordAuthentication: "scram-sha-256")
        return config
    }
}