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
/// Database dynamic role creation configuration for Valkey
public struct CreateValkeyRole: Sendable {
    /// The vault role name which maps to a dynamically generated database username
    public var vaultRoleName: String

    /// The name of the database connection to use for this role.
    public var databaseConnectionName: String

    /// Specifies the time to live (TTL) for the leases associated with this role. Defaults to system/engine default TTL time.
    public var defaultTimeToLive: Duration?

    /// Specifies the maximum TTL for the leases associated with this role. Defaults to sys/mounts's default TTL time;
    /// this value is allowed to be less than the mount max TTL (or, if not set, the system max TTL), but it is not allowed to be longer. See also The TTL General Case.
    public var maxTimeToLive: Duration?

    ///  Specifies the database statements executed to create and configure a user. e.g. `+@admin`
    public var creationStatements: [String]

    /// Specifies the configuration for the given `credential_type`. See documentation for details
    public var credentialConfig: [String: String]?

    public init(vaultRoleName: String,
                databaseConnectionName: String,
                defaultTimeToLive: Duration? = nil,
                maxTimeToLive: Duration? = nil,
                creationStatements: [String]) {
        self.vaultRoleName = vaultRoleName
        self.databaseConnectionName = databaseConnectionName
        self.defaultTimeToLive = defaultTimeToLive
        self.maxTimeToLive = maxTimeToLive
        self.creationStatements = creationStatements
    }
}
#endif
