import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

struct DatabaseConfig: Sendable {
    var host: String
    var port: Int
    var database: String
    var username: String
    var password: String
}

extension TodoConfig.Module {
    var databaseConfig: DatabaseConfig {
        get throws {
            let credentials = try JSONDecoder().decode(
                DatabaseCredentials.self,
                from: Data(postgresConfig.credentials.utf8)
            )

            return .init(
                host: postgresConfig.hostname,
                port: postgresConfig.port,
                database: postgresConfig.database,
                username: credentials.username,
                password: credentials.password
            )
        }
    }
}