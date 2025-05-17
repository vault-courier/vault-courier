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

    /// Database username
    public let username: String

    /// Database password
    public let password: String

    public let ttl: Int

    /// Last Vault rotation
    public let updatedAt: String

    /// Rotation strategy of credentials
    public let rotation: RotationStrategy?
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
            .period(.seconds(rotationPeriod))
        } else if let schedule = component.data.rotationSchedule {
            if let window = component.data.rotationWindow {
                .scheduled(.init(schedule: schedule,
                                 window: .seconds(window)))
            } else {
                .scheduled(.init(schedule: schedule, window: nil))
            }
        } else {
            nil
        }
    }
}
