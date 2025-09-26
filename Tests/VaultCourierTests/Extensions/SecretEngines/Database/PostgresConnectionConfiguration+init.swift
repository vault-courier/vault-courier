//===----------------------------------------------------------------------===//
//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//===----------------------------------------------------------------------===//

#if PklSupport
#if PostgresPluginSupport
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
#endif
#endif
