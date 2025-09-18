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
public struct StaticRoleCredentialsResponse: Sendable {
    public let requestID: String

    /// Database username
    public let username: String

    /// Database password
    public let password: String

    public let timeToLive: Duration

    /// Last Vault rotation
    public let updatedAt: String

    /// Rotation strategy of credentials
    public let rotation: RotationStrategy?
}
#endif
