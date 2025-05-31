import Hummingbird
import Logging
import VaultCourier

func connectToVault(
    logger: Logging.Logger,
    arguments: some AppArguments
) async throws -> DatabaseCredentials {
    return .init(username: "todos", password: "todos")
}