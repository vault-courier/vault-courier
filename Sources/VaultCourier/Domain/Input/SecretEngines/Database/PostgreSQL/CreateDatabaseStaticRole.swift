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

#if DatabaseEngineSupport
public struct CreateDatabaseStaticRole: Sendable {
    /// The corresponding role in the database of ``databaseUsername``
    public var vaultRoleName: String

    /// Specifies the database username that this Vault role corresponds to. See ``vaultRoleName``.
    public var databaseUsername: String

    /// The name of the database connection to use for this role.
    public var databaseConnectionName: String

    /// Strategy for credentials rotation
    public var rotation: RotationStrategy

    /// Specifies the database statements to be executed to rotate the password for the configured database user. Not every plugin type will support this functionality. See the plugin's API page for more information on support and formatting for this parameter.
    public var rotationStatements: [String]?

    /// Specifies the type of credential that will be generated for the role. Options include: `password`, `rsaPrivateKey`, `clientCertificate`. See the plugin's API page for credential types supported by individual databases.
    /// `PostgreSQL` plugin supports this, but the `Valkey` plugin does not.
    public var credentialType: DatabaseCredentialMethod?

    /// Specifies the configuration for the given ``credentialType``. See Vault/OpenBao documentation for details
    public var credentialConfig: [String: String]?

    public init(vaultRoleName: String,
                databaseUsername: String,
                databaseConnectionName: String,
                rotation: RotationStrategy,
                rotationStatements: [String]? = nil,
                credentialType: DatabaseCredentialMethod? = nil,
                credentialConfig: [String : String]? = nil) {
        self.vaultRoleName = vaultRoleName
        self.databaseUsername = databaseUsername
        self.databaseConnectionName = databaseConnectionName
        self.rotation = rotation
        self.rotationStatements = rotationStatements
        self.credentialType = credentialType
        self.credentialConfig = credentialConfig
    }
}

public enum RotationStrategy: Sendable {
    /// Specifies the amount of time Vault should wait before rotating the password. The minimum is 5 seconds. Uses duration format strings.
    case period(Duration)

    /// A cron-style string that will define the schedule on which rotations should occur.
    case scheduled(ScheduledRotation)
}

public struct ScheduledRotation: Sendable {
    /// This should be a "standard" cron-style string made of five fields of which each entry defines the minute, hour, day of month, month, and day of week respectively. For example, a value of  "0 0 * * SAT" will set rotations to occur on Saturday at 00:00.
    public let schedule: String

    /// Specifies the amount of time in which the rotation is allowed to occur starting from a given ``schedule``. If the credential is not rotated during this window, due to a failure or otherwise, it will not be rotated until the next scheduled rotation. The minimum is 1 hour. Uses duration format strings.
    public let window: Duration?

    public init(schedule: String, window: Duration?) {
        self.schedule = schedule
        self.window = window
    }
}

extension ScheduledRotation: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let window else {
            return schedule
        }
        return "\(schedule), window: \(window)"
    }
}

extension RotationStrategy: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .period(let period):
                return "Rotation.period(\(period))"
            case .scheduled(let scheduled):
                return "Rotation.scheduled(\(scheduled))"
        }
    }
}
#endif
