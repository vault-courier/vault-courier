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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

public struct DatabaseConnectionResponse: Sendable {
    public let requestId: String
    public let leaseId: String?
    public let leaseDuration: Int?
    public let renewable: Bool?
    public let allowedRoles: [String]
    public let connectionURL: URL?
    public let authMethod: PostgresAuthMethod?
    public let username: String
    public let plugin: Plugin?
    public let passwordPolicy: String?
    /// Root credential rotate statements
    public let rotateStatements: [String]

    public struct Plugin: Sendable {
        public let name: String
        public let version: String?
    }
}

extension DatabaseConnectionResponse {
    init(component: Components.Schemas.ReadDatabaseConfigResponse) {
        self.requestId = component.requestId
        self.leaseDuration = component.leaseDuration
        self.leaseId = component.leaseId
        self.renewable = component.renewable
        self.allowedRoles = component.data.allowedRoles
        self.connectionURL = URL(string: component.data.connectionDetails.connectionUrl)
        self.authMethod = .init(rawValue: component.data.connectionDetails.passwordAuthentication)
        self.username = component.data.connectionDetails.username
        let pluginVersion = component.data.pluginVersion
        let pluginName = component.data.pluginName
        self.plugin = pluginName.flatMap { Plugin(name: $0, version: pluginVersion) }
        self.passwordPolicy = component.data.passwordPolicy
        self.rotateStatements = component.data.rootCredentialsRotateStatements ?? []
    }
}
