import Logging
import VaultCourier

func connectToVault(
    logger: Logging.Logger
) async throws -> DatabaseCredentials {
    return .init(username: "todos", password: "todos")
}
