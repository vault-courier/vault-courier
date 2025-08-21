import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let databaseConfig  = try await connectToVault(logger: app.logger)

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: databaseConfig.host,
        port: databaseConfig.port,
        username: databaseConfig.username,
        password: databaseConfig.password,
        database: databaseConfig.database,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    // register routes
    try routes(app)
}
