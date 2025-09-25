import Logging
import VaultCourier
import Vapor
import struct Foundation.URL
import OpenAPIAsyncHTTPClient

func connectToVault(
    logger: Logging.Logger
) async throws -> DatabaseCredentials {
    guard let roleID = Environment.get("ROLE_ID"),
          let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
    else { fatalError("❌ Missing credentials for Vault authentication.") }

    // Read the secretID provided by the broker
    let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)

        // Create vault client.
    let vaultConfiguration = VaultClient.Configuration(
        apiURL: try URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1"),
        backgroundActivityLogger: logger
    )

    let client = Client(
        serverURL: vaultConfiguration.apiURL,
        transport: AsyncHTTPClientTransport()
    )

    let vaultClient = VaultClient(
        configuration: vaultConfiguration,
        client: client,
        authentication: .appRole(
            credentials: .init(roleID: roleID, secretID: secretID),
            isWrapped: true
        )
    )

    // Authenticate with vault
    guard try await vaultClient.authenticate()
    else { fatalError("❌ The app could not log in to Vault. Open investigation 🕵️") }

    // Read database credentials
    let response = try await vaultClient.databaseCredentials(staticRole: "static_server_role", enginePath: "database")
    return .init(username: response.username, password: response.password)
}
