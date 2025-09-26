//
//  ValkeyPluginTrait.swift
//  vault-courier
//
//  Created by Javier Cuesta on 30.04.25.
//

#if ValkeyPluginSupport
import Testing
import VaultCourier

struct ValkeyPluginTrait: SuiteTrait, TestScoping {
    let connectionName: String
    let enginePath: String

    static func valkeyConnectionConfiguration(_ name: String) -> ValkeyConnection {
        // Host name inside container
        let host = env("VALKEY_HOST") ?? "valkey-cache"
        let port = env("VALKEY_PORT").flatMap(Int.init(_:)) ?? 6379

        let vaultUsername = env("VAULT_DB_USERNAME") ?? "vault_user"
        let vaultPassword = env("VAULT_DB_PASSWORD") ?? "init_password"

        let config = ValkeyConnection(
            connection: name,
            verifyConnection: false,
            allowedRoles: ["*"],
            host: host,
            port: UInt16(port),
            username: vaultUsername,
            password: vaultPassword,
            tls: nil,
            rootRotationStatements: ["+@all", "+@admin"]
        )
        return config
    }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let vaultClient = VaultClient.current
        let mountConfig = EnableSecretMountConfig(mountType: "database", path: enginePath)
        let config = Self.valkeyConnectionConfiguration(connectionName)
        try await vaultClient.enableSecretEngine(mountConfig: mountConfig)
        try await vaultClient.valkeyConnection(configuration: config, enginePath: enginePath)
        try await vaultClient.rotateRoot(connection: connectionName, enginePath: enginePath)

        try await function()

        try await vaultClient.deleteDatabaseConnection(connectionName, enginePath: enginePath)
    }
}

extension SuiteTrait where Self == ValkeyPluginTrait {
    static func setupValkeyConnection(name: String = "valkey_db",
                                      enginePath: String = "database") -> Self {
        return Self(connectionName: name, enginePath: enginePath)
    }
}
#endif
