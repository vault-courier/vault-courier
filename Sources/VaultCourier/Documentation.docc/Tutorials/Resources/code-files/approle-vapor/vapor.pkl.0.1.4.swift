import Logging
import VaultCourier
import Vapor
import struct Foundation.URL
import OpenAPIAsyncHTTPClient

func connectToVault(
    logger: Logging.Logger
) async throws -> DatabaseConfig {
    guard let roleID = Environment.get("ROLE_ID"),
          let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
    else { fatalError("❌ Missing credentials for Vault authentication.") }

    // Read the secretID provided by the broker
    let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)

    // Create vault client.
    let vaultClient = VaultClient(
        configuration: .defaultHttp(backgroundActivityLogger: logger),
        clientTransport: AsyncHTTPClientTransport()
    )

    // Authenticate with vault
    do {
        try await vaultClient.login(
            method: .appRole(
                path: "approle",
                credentials: .init(roleID: roleID, secretID: secretID)
            )
        )
    }
    catch {
        fatalError("❌ The app could not log in to Vault. Open investigation 🕵️")
    }

    // Read database configuration
    let reader = try vaultClient.makeDatabaseCredentialReader(mountPath: "database")

    let config = try await withEvaluator(options: .preconfigured.withResourceReader(reader)) { evaluator in
        try await TodoConfig.loadFrom(
            evaluator: evaluator,
            source: .url(.init(filePath: "todoConfig.stage.pkl").absoluteURL)
        )
    }

    return try config.databaseConfig
}
