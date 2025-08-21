import Logging
import VaultCourier
import Vapor
import struct Foundation.URL

func connectToVault(
    logger: Logging.Logger
) async throws -> DatabaseCredentials {
    guard let roleID = Environment.get("ROLE_ID"),
          let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
    else { fatalError("❌ Missing credentials for Vault authentication.") }

    // Read the secretID provided by the broker
    let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)























    return .init(username: "todos", password: "todos")
}
