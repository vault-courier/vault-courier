import Hummingbird
import Logging
import VaultCourier
import struct Foundation.URL


func connectToVault(
    logger: Logging.Logger,
    arguments: some AppArguments
) async throws -> DatabaseCredentials {
    let environment = Environment()
    guard let roleID = environment.get("ROLE_ID"),
          let secretIdFilePath = environment.get("SECRET_ID_FILEPATH")
    else { fatalError("❌ Missing credentials for Vault authentication.") }

    // Read the secretID provided by the broker
    let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)





















    // Return database credentials
    return .init(username: "todos", password: "todos")
}