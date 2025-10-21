import VaultCourier
import OpenAPIAsyncHTTPClient
import PostgresNIO
import struct Hummingbird.Environment
import struct Foundation.URL

let environment = Environment()
guard let roleID = environment.get("ROLE_ID"),
      let secretIdFilePath = environment.get("SECRET_ID_FILEPATH")
else { fatalError("❌ App could not login with Vault. Missing credentials") }

// 1. Read the secretID provided by the broker
let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)
let logger = Logger(label: "migrator")

// 2. Create a vault client.
let vaultClient = VaultClient(
    configuration: .defaultHttp(backgroundActivityLogger: logger),
    clientTransport: AsyncHTTPClientTransport()
)

// 3. Authenticate with vault
do {
    try await vaultClient.login(
        method: .appRole(
            path: "approle",
            credentials: .init(roleID: roleID, secretID: secretID)
        )
    )
} catch {
    fatalError("❌ The app could not log in to Vault. Open investigation 🕵️")
}
else { fatalError("❌ The app could not log in to Vault. Open investigation 🕵️") }
