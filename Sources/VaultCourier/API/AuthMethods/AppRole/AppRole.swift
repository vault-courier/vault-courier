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

#if AppRoleSupport
#if canImport(FoundationEssentials)
import FoundationEssentials
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import protocol Foundation.LocalizedError
#endif
import VaultUtilities

extension VaultClient {
    /// Creates a new AppRole
    public func createAppRole(
        _ appRole: CreateAppRole,
        mountPath: String? = nil
    ) async throws {
        try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.createAppRole(appRole)
        }
    }

    /// Read AppRole
    /// - Parameter name: role name
    public func readAppRole(
        name: String,
        mountPath: String? = nil
    ) async throws -> ReadAppRoleResponse {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.readAppRole(name: name)
        }
    }

    
    /// Delete existing AppRole
    /// - Parameter name: role name
    public func deleteAppRole(
        name: String,
        mountPath: String? = nil
    ) async throws {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.deleteAppRole(name: name)
        }
    }

    
    /// Get AppRole ID
    /// - Parameter name: role name
    public func appRoleID(
        name: String,
        mountPath: String? = nil
    ) async throws -> AppRoleIDResponse {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.appRoleID(name: name)
        }
    }

    /// Get AppRole ID
    /// - Parameter name: role name
    public func wrapAppRoleID(
        name: String,
        mountPath: String? = nil,
        wrapTimeToLive: Duration
    ) async throws -> WrappedTokenResponse {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.wrapAppRoleID(name: name, wrapTimeToLive: wrapTimeToLive)
        }
    }
    
    /// Generate AppRole secretID
    /// - Parameter capabilities: the properties this generated secretID must have
    /// - Returns: Either a wrapped response token or the secretID
    public func generateAppSecretId(
        capabilities: GenerateAppRoleToken,
        mountPath: String? = nil
    ) async throws -> AppRoleSecretIdResponse {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.generateAppSecretId(capabilities: capabilities)
        }
    }

    
    /// Fetches the login session token and its information.
    ///
    /// if ``VaultCourier/CreateAppRole/bindSecretID`` is enabled (the default) on the AppRole, `secretID` is required too. Any other bound authentication values on the AppRole (such as client IP CIDR) are also evaluated.
    ///
    /// - Note: this method does not set the token session of the vault client. See the ``VaultCourier/VaultClient/login()`` which initiates login from the given authentication
    /// method and sets the session token of the client.
    /// - Parameters:
    ///   - roleID: RoleID of the AppRole
    ///   - secretID: SecretID belonging to AppRole
    /// - Returns: ``VaultAuthResponse``
    public func loginToken(
        roleID: String,
        secretID: String,
        mountPath: String? = nil
    ) async throws -> VaultAuthResponse {
        return try await withAppRoleProvider(mountPath: mountPath) { provider in
            try await provider.loginToken(roleID: roleID, secretID: secretID)
        }
    }
}
#endif
