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

#if PostgresPluginSupport || ValkeyPluginSupport
public enum DatabaseStaticRoleConfig: Sendable {
    #if PostgresPluginSupport
    case postgres(PostgresStaticRoleConfig)
    #endif
    #if ValkeyPluginSupport
    case valkey(ValkeyStaticRoleConfig)
    #endif
}
#endif

#if DatabaseEngineSupport
public enum RotationStrategy: Sendable {
    /// Specifies the amount of time Vault should wait before rotating the password. The minimum is 5 seconds
    case period(Duration)

    /// A cron-style string that will define the schedule on which rotations should occur.
    case scheduled(ScheduledRotation)
}

public struct ScheduledRotation: Sendable {
    /// This should be a "standard" cron-style string made of five fields of which each entry defines the minute, hour, day of month, month, and day of week respectively. For example, a value of  "0 0 * * SAT" will set rotations to occur on Saturday at 00:00.
    public let schedule: String

    /// Specifies the amount of time in which the rotation is allowed to occur starting from a given ``schedule``. If the credential is not rotated during this window, due to a failure or otherwise, it will not be rotated until the next scheduled rotation. The minimum is 1 hour
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
