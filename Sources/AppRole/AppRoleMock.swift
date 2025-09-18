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

import Utils

package struct AppRoleMock: APIProtocol {
    package var appRolePath: String
    package var credentials: AppRoleCredentials

    package init(appRolePath: String,
                credentials: AppRoleCredentials,
                authReadApproleAction: AuthReadApproleSignature? = nil,
                authCreateApproleAction: AuthCreateApproleSignature? = nil,
                authDeleteApproleAction: AuthDeleteApproleSignature? = nil,
                authReadRoleIdAction: AuthReadRoleIdSignature? = nil,
                authApproleSecretIdAction: AuthApproleSecretIdSignature? = nil,
                authReadApproleSecretIdWithAccessorAction: AuthReadApproleSecretIdWithAccessorSignature? = nil,
                authDestroyApproleSecretIdWithAccessorAction: AuthDestroyApproleSecretIdWithAccessorSignature? = nil,
                authApproleLoginAction: AuthApproleLoginSignature? = nil) {
        self.appRolePath = appRolePath
        self.credentials = credentials
        self.authReadApproleAction = authReadApproleAction
        self.authCreateApproleAction = authCreateApproleAction
        self.authDeleteApproleAction = authDeleteApproleAction
        self.authReadRoleIdAction = authReadRoleIdAction
        self.authApproleSecretIdAction = authApproleSecretIdAction
        self.authReadApproleSecretIdWithAccessorAction = authReadApproleSecretIdWithAccessorAction
        self.authDestroyApproleSecretIdWithAccessorAction = authDestroyApproleSecretIdWithAccessorAction
        self.authApproleLoginAction = authApproleLoginAction
    }

    package typealias AuthReadApproleSignature
        = @Sendable (Operations.AuthReadApprole.Input) async throws -> Operations.AuthReadApprole.Output
    package var authReadApproleAction: AuthReadApproleSignature?
    package func authReadApprole(
        _ input: Operations.AuthReadApprole.Input
    ) async throws -> Operations.AuthReadApprole.Output {
        guard let block = authReadApproleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthCreateApproleSignature
        = @Sendable (Operations.AuthCreateApprole.Input) async throws -> Operations.AuthCreateApprole.Output
    package var authCreateApproleAction: AuthCreateApproleSignature?
    package func authCreateApprole(
        _ input: Operations.AuthCreateApprole.Input
    ) async throws -> Operations.AuthCreateApprole.Output {
        guard let block = authCreateApproleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthDeleteApproleSignature
        = @Sendable (Operations.AuthDeleteApprole.Input) async throws -> Operations.AuthDeleteApprole.Output
    public var authDeleteApproleAction: AuthDeleteApproleSignature?
    public func authDeleteApprole(
        _ input: Operations.AuthDeleteApprole.Input
    ) async throws -> Operations.AuthDeleteApprole.Output {
        guard let block = authDeleteApproleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthReadRoleIdSignature
        = @Sendable (Operations.AuthReadRoleId.Input) async throws -> Operations.AuthReadRoleId.Output
    package var authReadRoleIdAction: AuthReadRoleIdSignature?
    package func authReadRoleId(
        _ input: Operations.AuthReadRoleId.Input
    ) async throws -> Operations.AuthReadRoleId.Output {
        guard let block = authReadRoleIdAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthApproleSecretIdSignature
        = @Sendable (Operations.AuthApproleSecretId.Input) async throws -> Operations.AuthApproleSecretId.Output
    package var authApproleSecretIdAction: AuthApproleSecretIdSignature?
    package func authApproleSecretId(
        _ input: Operations.AuthApproleSecretId.Input
    ) async throws -> Operations.AuthApproleSecretId.Output {
        guard let block = authApproleSecretIdAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthReadApproleSecretIdWithAccessorSignature
        = @Sendable (Operations.AuthReadApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output
    package var authReadApproleSecretIdWithAccessorAction: AuthReadApproleSecretIdWithAccessorSignature?
    package func authReadApproleSecretIdWithAccessor(
        _ input: Operations.AuthReadApproleSecretIdWithAccessor.Input
    ) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output {
        guard let block = authReadApproleSecretIdWithAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthDestroyApproleSecretIdWithAccessorSignature
        = @Sendable (Operations.AuthDestroyApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output
    package var authDestroyApproleSecretIdWithAccessorAction: AuthDestroyApproleSecretIdWithAccessorSignature?
    package func authDestroyApproleSecretIdWithAccessor(
        _ input: Operations.AuthDestroyApproleSecretIdWithAccessor.Input
    ) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output {
        guard let block = authDestroyApproleSecretIdWithAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias AuthApproleLoginSignature = @Sendable (Operations.AuthApproleLogin.Input) async throws -> Operations.AuthApproleLogin.Output
    package var authApproleLoginAction: AuthApproleLoginSignature?
    package func authApproleLogin(
        _ input: Operations.AuthApproleLogin.Input
    ) async throws -> Operations.AuthApproleLogin.Output {
        guard let block = authApproleLoginAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
