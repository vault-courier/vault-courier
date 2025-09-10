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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

public struct ValkeyConnectionResponse: Sendable {
    public let requestID: String

    /// List of the _vault_ roles allowed to use this connection. If contains a `*` any role can use this connection.
    /// Currently, roles and connections are bounded if this parameter is different than `*`. This means credentials cannot be generated and accessed by a role which is not on the list.
    public let allowedRoles: [String]

    /// Specifies the PostgreSQL DSN
    public let host: String

    public let port: UInt16

    /// Vault database ("Root") user.
    public let username: String

    /// Plugin information
    public let plugin: VaultPlugin?

    public let passwordPolicy: String?

    /// Root credential rotate statements
    public let rotateStatements: [String]
}

#endif
