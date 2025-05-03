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
struct DynamicRoleCredentials: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    var roleName: String = "dynamic_role"

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()

        let creationStatements = [
            #"CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;"#,
            #"GRANT read_only TO "{{name}}";"#
        ]
        try await vaultClient.create(dynamicRole: .init(vaultRoleName: roleName,
                                                        databaseConnectionName: connectionName,
                                                        defaultTTL: "1h",
                                                        maxTTL: "24h",
                                                        creationStatements: creationStatements),
                                     enginePath: enginePath)

        let response = try await vaultClient.databaseCredentials(dynamicRole: roleName, enginePath: enginePath)
        print("""
        lease_id           \(response?.leaseId ?? "")
        lease_duration     \(response?.leaseDuration ?? 0)
        lease_renewable    \(response?.renewable ?? false)
        password           \(response?.password ?? "")
        username           \(response?.username ?? "")    
        """)
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
}
