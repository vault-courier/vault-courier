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

public struct StaticRoleCredentialsResponse: Sendable {
    public let requestId: String
    public let leaseId: String?
    public let leaseDuration: Int?
    public let renewable: Bool?
    public let username: String
    public let password: String
    public let ttl: Int
    /// Last Vault rotation
    public let updatedAt: String
    public let rotation: Rotation?
}

public enum Rotation: Sendable {
    case period(Int)
    case scheduled(ScheduledRotation)
}

public struct ScheduledRotation: Sendable {
    public let schedule: String
    public let window: Int?
}

extension ScheduledRotation: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let window else {
            return schedule
        }
        return "\(schedule), window: \(window)"
    }
}

extension Rotation: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .period(let period):
                return ".period(\(period))"
            case .scheduled(let scheduled):
                return ".scheduled(\(scheduled))"
        }
    }
}

extension StaticRoleCredentialsResponse {
    init(component: Components.Schemas.ReadStaticRoleCredentialsResponse) {
        self.requestId = component.requestId
        self.leaseDuration = component.leaseDuration
        self.leaseId = component.leaseId
        self.renewable = component.renewable
        self.username = component.data.username
        self.password = component.data.password
        self.ttl = component.data.ttl
        self.updatedAt = component.data.lastVaultRotation
        self.rotation = if let rotationPeriod = component.data.rotationPeriod {
            .period(rotationPeriod)
        } else if let schedule = component.data.rotationSchedule {
            .scheduled(.init(schedule: schedule, window: component.data.rotationWindow))
        } else {
            nil
        }
    }
}
