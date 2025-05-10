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


public struct CreateDatabaseStaticRole: Sendable {
    /// The corresponfing role in the database of `db_username`
    public var vaultRoleName: String

    /// Specifies the database username that this Vault role corresponds to. See `vault_role_name`.
    public var databaseUsername: String

    /// The name of the database connection to use for this role.
    public var databaseConnectionName: String

    /// Specifies the amount of time Vault should wait before rotating the password. The minimum is 5 seconds. Uses duration format strings. Mutually exclusive with `rotation_schedule`.
    public var rotationPeriod: String?

    /// A cron-style string that will define the schedule on which rotations should occur. This should be a "standard" cron-style string made of five fields of which each entry defines the minute, hour, day of month, month, and day of week respectively. For example, a value of ``0 0 * * SAT`` will set rotations to occur on Saturday at 00:00. Mutually exclusive with `rotation_period`."
    public var rotationSchedule: String?

    /// Specifies the amount of time in which the rotation is allowed to occur starting from a given `rotation_schedule`. If the credential is not rotated during this window, due to a failure or otherwise, it will not be rotated until the next scheduled rotation. The minimum is 1 hour. Uses duration format strings. Optional when `rotation_schedule` is set and disallowed when` rotation_period` is set."
    public var rotationWindow: String?

    /// Specifies the database statements to be executed to rotate the password for the configured database user. Not every plugin type will support this functionality. See the plugin's API page for more information on support and formatting for this parameter.
    public var rotationStatements: [String]?

    /// Specifies the type of credential that will be generated for the role. Options include: password, rsa_private_key, client_certificate. See the plugin's API page for credential types supported by individual databases.
    public var credentialType: String?

    /// Specifies the configuration for the given `credential_type`. See documentation for details
    public var credentialConfig: [String: String]?

    public init(vaultRoleName: String,
                databaseUsername: String,
                databaseConnectionName: String,
                rotationPeriod: String? = nil,
                rotationSchedule: String? = nil,
                rotationWindow: String? = nil,
                rotationStatements: [String]? = nil,
                credentialType: String? = nil,
                credentialConfig: [String : String]? = nil) {
        self.vaultRoleName = vaultRoleName
        self.databaseUsername = databaseUsername
        self.databaseConnectionName = databaseConnectionName
        self.rotationPeriod = rotationPeriod
        self.rotationSchedule = rotationSchedule
        self.rotationWindow = rotationWindow
        self.rotationStatements = rotationStatements
        self.credentialType = credentialType
        self.credentialConfig = credentialConfig
    }
}
