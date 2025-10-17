//
//  PostgresPluginTrait.swift
//  vault-courier
//
//  Created by Javier Cuesta on 30.04.25.
//

#if PostgresPluginSupport
import Testing
import VaultCourier

extension VaultClient {
    @TaskLocal static var postgresConnectionConfig: (mountConfig: EnableSecretMountConfig, connectionConfig: PostgresConnectionConfig) =
        (
            mountConfig: EnableSecretMountConfig(mountType: "database", path: "database"),
            connectionConfig: PostgresPluginTrait.postgresConnectionConfiguration("pg_database")
        )
}

struct PostgresPluginTrait: SuiteTrait, TestScoping {
    let connectionName: String
    let enginePath: String

    static func postgresConnectionConfiguration(_ name: String) -> PostgresConnectionConfig {
        // Host name inside container
        let host = env("POSTGRES_HOSTNAME") ?? "pg-db"
        let port = env("POSTGRES_PORT").flatMap(Int.init(_:)) ?? 5432
        let databaseName = env("POSTGRES_DB") ?? "test_database"
        let sslMode = "disable"
        let connectionURL = "postgresql://{{username}}:{{password}}@\(host):\(port)/\(databaseName)?sslmode=\(sslMode)"
        let vaultUsername = env("VAULT_DB_USERNAME") ?? "vault_user"
        let vaultPassword = env("VAULT_DB_PASSWORD") ?? "init_password"
        let config = PostgresConnectionConfig(connection: name,
                                              allowedRoles: ["*"],
                                              connectionUrl: connectionURL,
                                              username: vaultUsername,
                                              password: vaultPassword,
                                              passwordAuthentication: .scramSHA256)
        return config
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let vaultClient = VaultClient.current
        let mountConfig = EnableSecretMountConfig(mountType: "database", path: enginePath)
        let config = Self.postgresConnectionConfiguration(connectionName)
        try await vaultClient.enableSecretEngine(mountConfig: mountConfig)
        try await vaultClient.createPostgresConnection(configuration: config, mountPath: enginePath)
        try await vaultClient.rotateRoot(connection: connectionName, mountPath: enginePath)

        try await VaultClient.$postgresConnectionConfig.withValue((mountConfig, config)) {
            try await function()
        }

        try await vaultClient.deleteDatabaseConnection(connectionName, mountPath: enginePath)
    }
}

extension SuiteTrait where Self == PostgresPluginTrait {
    static func setupPostgresConnection(name: String = "postgres_db",
                                        enginePath: String = "database") -> Self {
        return Self(connectionName: name, enginePath: enginePath)
    }
}
#endif
