import VaultCourier
import OpenAPIAsyncHTTPClient
import PostgresNIO
import struct Vapor.Environment
import struct Foundation.URL

guard let roleID = Environment.get("ROLE_ID"),
      let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
else { fatalError("❌ Missing credentials for Vault authentication.") }

// 1. Read the secretID provided by the broker
let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)
let logger = Logger(label: "migrator")

// 2. Create a vault client.
let vaultURL = try URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
let vaultConfiguration = VaultClient.Configuration(
    apiURL: vaultURL,
    databaseMountPath: "database",
    backgroundActivityLogger: logger
)

let vaultClient = VaultClient(
    configuration: vaultConfiguration,
    client: Client(
        serverURL: vaultConfiguration.apiURL,
        transport: AsyncHTTPClientTransport()
    ),
    authentication: .appRole(
        credentials: .init(roleID: roleID, secretID: secretID),
        isWrapped: false
    )
)
// 3. Authenticate with vault
guard try await vaultClient.authenticate()
else { fatalError("❌ The app could not log in to Vault. Open investigation 🕵️") }