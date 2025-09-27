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

#if ValkeyPluginSupport

/// Valkey Connection Configuration response
public struct ValkeyConnectionResponse: Sendable {
    public let requestID: String

    /// List of the _vault_ roles allowed to use this connection. If contains a `*` any role can use this connection.
    /// Currently, roles and connections are bounded if this parameter is different than `*`. This means credentials cannot be generated and accessed by a role which is not on the list.
    public let allowedRoles: [String]

    /// Valkey's host
    public let host: String

    /// Valkey's port
    public let port: UInt16

    /// Specifies if the connection is using TLS
    public let useTLS: Bool

    /// Vault database ("Root") user.
    public let username: String

    /// Plugin information
    public let plugin: VaultPlugin?

    /// The name of the password policy to use when generating passwords for this database. If not specified, this will use a default policy defined as: 20 characters with at least 1 uppercase, 1 lowercase, 1 number, and 1 dash character.
    public let passwordPolicy: String?

    /// Root credential rotate statements
    public let rotateStatements: [String]
}

#endif
