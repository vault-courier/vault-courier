import VaultCourier

extension PostgresConnectionConfiguration {
    init(_ module: PostgresDatabaseConnection.Module) {
        self.init(connection: module.connection,
                  verifyConnection: module.verify_connection ?? true,
                  allowedRoles: module.allowed_roles ?? [],
                  connectionUrl: module.connection_url,
                  maxOpenConnections: module.max_open_connections.flatMap(Int.init),
                  maxIdleConnections: module.max_idle_connections.flatMap(Int.init),
                  maxConnectionLifetime: module.max_connection_lifetime,
                  username: module.username,
                  password: module.password,
                  tlsCa: module.tls_ca,
                  tlsCertificate: module.tls_certificate,
                  privateKey: module.private_key,
                  usernameTemplate: module.username_template,
                  disableEscaping: module.disable_escaping ?? false,
                  passwordAuthentication: PostgresAuthMethod(rawValue: module.password_authentication) ?? .password,
                  rootRotationStatements: module.root_rotation_statements ?? [])
    }
}