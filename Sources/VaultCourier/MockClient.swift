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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
import protocol Foundation.LocalizedError
#else
import protocol Foundation.LocalizedError
#endif

public struct MockClient: APIProtocol {

    public init() {}

    // MARK: Write KV Secret
    public typealias WriteKvSecretsSignature = @Sendable (Operations.WriteKvSecrets.Input) async throws -> Operations.WriteKvSecrets.Output
    public var writeKvSecretsAction: WriteKvSecretsSignature?
    public func writeKvSecrets(
        _ input: Operations.WriteKvSecrets.Input
    ) async throws -> Operations.WriteKvSecrets.Output {
        guard let block = writeKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read KV Secret
    public typealias ReadKvSecretsSignature = @Sendable (Operations.ReadKvSecrets.Input) async throws -> Operations.ReadKvSecrets.Output
    public var readKvSecretsAction: ReadKvSecretsSignature?
    public func readKvSecrets(
        _ input: Operations.ReadKvSecrets.Input
    ) async throws -> Operations.ReadKvSecrets.Output {
        guard let block = readKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Configure Database Connection
    public typealias ConfigureDatabaseSignature = @Sendable (Operations.ConfigureDatabase.Input) async throws -> Operations.ConfigureDatabase.Output
    public var configureDatabaseAction: ConfigureDatabaseSignature?
    public func configureDatabase(
        _ input: Operations.ConfigureDatabase.Input
    ) async throws -> Operations.ConfigureDatabase.Output {
        guard let block = configureDatabaseAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read Database Connection
    public typealias ReadDatabaseConfigurationSignature = @Sendable (Operations.ReadDatabaseConfiguration.Input) async throws -> Operations.ReadDatabaseConfiguration.Output
    public var readDatabaseConfigurationAction: ReadDatabaseConfigurationSignature?
    public func readDatabaseConfiguration(
        _ input: Operations.ReadDatabaseConfiguration.Input
    ) async throws -> Operations.ReadDatabaseConfiguration.Output {
        guard let block = readDatabaseConfigurationAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Delete Database Connection
    public typealias DeleteDatabaseConnectionSignature = @Sendable (Operations.DeleteDatabaseConnection.Input) async throws -> Operations.DeleteDatabaseConnection.Output
    public var deleteDatabaseConnectionAction: DeleteDatabaseConnectionSignature?
    public func deleteDatabaseConnection(
        _ input: Operations.DeleteDatabaseConnection.Input
    ) async throws -> Operations.DeleteDatabaseConnection.Output {
        guard let block = deleteDatabaseConnectionAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Reset Database Connection
    public typealias DatabaseResetSignature = @Sendable (Operations.DatabaseReset.Input) async throws -> Operations.DatabaseReset.Output
    public var databaseResetAction: DatabaseResetSignature?
    public func databaseReset(
        _ input: Operations.DatabaseReset.Input
    ) async throws -> Operations.DatabaseReset.Output {
        guard let block = databaseResetAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Reload Database Plugin
    public typealias ReloadDatabasePluginSignature = @Sendable (Operations.ReloadDatabasePlugin.Input) async throws -> Operations.ReloadDatabasePlugin.Output
    public var reloadDatabasePluginAction: ReloadDatabasePluginSignature?
    public func reloadDatabasePlugin(
        _ input: Operations.ReloadDatabasePlugin.Input
    ) async throws -> Operations.ReloadDatabasePlugin.Output {
        guard let block = reloadDatabasePluginAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Rotate Vault Root Database Password
    public typealias DatabaseRotateRootSignature = @Sendable (Operations.DatabaseRotateRoot.Input) async throws -> Operations.DatabaseRotateRoot.Output
    public var databaseRotateRootAction: DatabaseRotateRootSignature?
    public func databaseRotateRoot(
        _ input: Operations.DatabaseRotateRoot.Input
    ) async throws -> Operations.DatabaseRotateRoot.Output {
        guard let block = databaseRotateRootAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read Static Role Credentials
    public typealias DatabaseReadStaticRoleCredentialsSignature = @Sendable (Operations.DatabaseReadStaticRoleCredentials.Input) async throws -> Operations.DatabaseReadStaticRoleCredentials.Output
    public var databaseReadStaticRoleCredentialsAction: DatabaseReadStaticRoleCredentialsSignature?
    public func databaseReadStaticRoleCredentials(
        _ input: Operations.DatabaseReadStaticRoleCredentials.Input
    ) async throws -> Operations.DatabaseReadStaticRoleCredentials.Output {
        guard let block = databaseReadStaticRoleCredentialsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read Database Static Role
    public typealias DatabaseReadStaticRoleSignature = @Sendable (Operations.DatabaseReadStaticRole.Input) async throws -> Operations.DatabaseReadStaticRole.Output
    public var databaseReadStaticRoleAction: DatabaseReadStaticRoleSignature?
    public func databaseReadStaticRole(
        _ input: Operations.DatabaseReadStaticRole.Input
    ) async throws -> Operations.DatabaseReadStaticRole.Output {
        guard let block = databaseReadStaticRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Delete Database Static Role
    public typealias DatabaseDeleteStaticRoleSignature = @Sendable (Operations.DatabaseDeleteStaticRole.Input) async throws -> Operations.DatabaseDeleteStaticRole.Output
    public var databaseDeleteStaticRoleAction: DatabaseDeleteStaticRoleSignature?
    public func databaseDeleteStaticRole(
        _ input: Operations.DatabaseDeleteStaticRole.Input
    ) async throws -> Operations.DatabaseDeleteStaticRole.Output {
        guard let block = databaseDeleteStaticRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Create Database Static Role
    public typealias DatabaseCreateStaticRoleSignature = @Sendable (Operations.DatabaseCreateStaticRole.Input) async throws -> Operations.DatabaseCreateStaticRole.Output
    public var databaseCreateStaticRoleAction: DatabaseCreateStaticRoleSignature?
    public func databaseCreateStaticRole(
        _ input: Operations.DatabaseCreateStaticRole.Input
    ) async throws -> Operations.DatabaseCreateStaticRole.Output {
        guard let block = databaseCreateStaticRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read Role Credentials
    public typealias DatabaseReadRoleCredentialsSignature = @Sendable (Operations.DatabaseReadRoleCredentials.Input) async throws -> Operations.DatabaseReadRoleCredentials.Output
    public var databaseReadRoleCredentialsAction: DatabaseReadRoleCredentialsSignature?
    public func databaseReadRoleCredentials(
        _ input: Operations.DatabaseReadRoleCredentials.Input
    ) async throws -> Operations.DatabaseReadRoleCredentials.Output {
        guard let block = databaseReadRoleCredentialsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Delete Database Role
    public typealias DatabaseDeleteRoleSignature = @Sendable (Operations.DatabaseDeleteRole.Input) async throws -> Operations.DatabaseDeleteRole.Output
    public var databaseDeleteRoleAction: DatabaseDeleteRoleSignature?
    public func databaseDeleteRole(
        _ input: Operations.DatabaseDeleteRole.Input
    ) async throws -> Operations.DatabaseDeleteRole.Output {
        guard let block = databaseDeleteRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Create Database Role
    public typealias DatabaseCreateRoleSignature = @Sendable (Operations.DatabaseCreateRole.Input) async throws -> Operations.DatabaseCreateRole.Output
    public var databaseCreateRoleAction: DatabaseCreateRoleSignature?
    public func databaseCreateRole(
        _ input: Operations.DatabaseCreateRole.Input
    ) async throws -> Operations.DatabaseCreateRole.Output {
        guard let block = databaseCreateRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Read Database Role
    public typealias DatabaseReadRoleSignature = @Sendable (Operations.DatabaseReadRole.Input) async throws -> Operations.DatabaseReadRole.Output
    public var databaseReadRoleAction: DatabaseReadRoleSignature?
    public func databaseReadRole(
        _ input: Operations.DatabaseReadRole.Input
    ) async throws -> Operations.DatabaseReadRole.Output {
        guard let block = databaseReadRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Policy
    public typealias WriteAclPolicySignature = @Sendable (Operations.PoliciesWriteAclPolicy.Input) async throws -> Operations.PoliciesWriteAclPolicy.Output
    public var writeAclPolicyAction: WriteAclPolicySignature?
    public func policiesWriteAclPolicy(
        _ input: Operations.PoliciesWriteAclPolicy.Input
    ) async throws -> Operations.PoliciesWriteAclPolicy.Output {
        guard let block = writeAclPolicyAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthApproleLoginSignature = @Sendable (Operations.AuthApproleLogin.Input) async throws -> Operations.AuthApproleLogin.Output
    public var authApproleLoginAction: AuthApproleLoginSignature?
    public func authApproleLogin(
        _ input: Operations.AuthApproleLogin.Input
    ) async throws -> Operations.AuthApproleLogin.Output {
        guard let block = authApproleLoginAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }


    public typealias EnableSecretsEngineSignature
        = @Sendable (Operations.MountsEnableSecretsEngine.Input) async throws -> Operations.MountsEnableSecretsEngine.Output
    public var enableSecretsEngineAction: EnableSecretsEngineSignature?
    public func mountsEnableSecretsEngine(
        _ input: Operations.MountsEnableSecretsEngine.Input
    ) async throws -> Operations.MountsEnableSecretsEngine.Output {
        guard let block = enableSecretsEngineAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }



    // MARK: AppRole
    public typealias AuthReadApproleSignature
        = @Sendable (Operations.AuthReadApprole.Input) async throws -> Operations.AuthReadApprole.Output
    public var authReadApproleAction: AuthReadApproleSignature?
    public func authReadApprole(
        _ input: Operations.AuthReadApprole.Input
    ) async throws -> Operations.AuthReadApprole.Output {
        guard let block = authReadApproleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthCreateApproleSignature
        = @Sendable (Operations.AuthCreateApprole.Input) async throws -> Operations.AuthCreateApprole.Output
    public var authCreateApproleAction: AuthCreateApproleSignature?
    public func authCreateApprole(
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

    public typealias AuthReadRoleIdSignature
        = @Sendable (Operations.AuthReadRoleId.Input) async throws -> Operations.AuthReadRoleId.Output
    public var authReadRoleIdAction: AuthReadRoleIdSignature?
    public func authReadRoleId(
        _ input: Operations.AuthReadRoleId.Input
    ) async throws -> Operations.AuthReadRoleId.Output {
        guard let block = authReadRoleIdAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthApproleSecretIdSignature
        = @Sendable (Operations.AuthApproleSecretId.Input) async throws -> Operations.AuthApproleSecretId.Output
    public var authApproleSecretIdAction: AuthApproleSecretIdSignature?
    public func authApproleSecretId(
        _ input: Operations.AuthApproleSecretId.Input
    ) async throws -> Operations.AuthApproleSecretId.Output {
        guard let block = authApproleSecretIdAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthReadApproleSecretIdWithAccessorSignature
        = @Sendable (Operations.AuthReadApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output
    public var authReadApproleSecretIdWithAccessorAction: AuthReadApproleSecretIdWithAccessorSignature?
    public func authReadApproleSecretIdWithAccessor(
        _ input: Operations.AuthReadApproleSecretIdWithAccessor.Input
    ) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output {
        guard let block = authReadApproleSecretIdWithAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias AuthDestroyApproleSecretIdWithAccessorSignature
        = @Sendable (Operations.AuthDestroyApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output
    public var authDestroyApproleSecretIdWithAccessorAction: AuthDestroyApproleSecretIdWithAccessorSignature?
    public func authDestroyApproleSecretIdWithAccessor(
        _ input: Operations.AuthDestroyApproleSecretIdWithAccessor.Input
    ) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output {
        guard let block = authDestroyApproleSecretIdWithAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Unwrap
    public typealias UnwrapSignature = @Sendable (Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output
    public var unwrapAction: UnwrapSignature?
    public func unwrap(_ input: Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output {
        guard let block = unwrapAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenCreateSignature = @Sendable (Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output
    public var tokenCreateAction: TokenCreateSignature?
    public func tokenCreate(_ input: Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output {
        guard let block = tokenCreateAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    // MARK: Auth

    public typealias EnableAuthSignature = @Sendable (Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output
    public var enableAuthAction: EnableAuthSignature?
    public func authEnableMethod(_ input: Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output {
        guard let block = enableAuthAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias DisableAuthMethodSignature = @Sendable (Operations.AuthDisableMethod.Input) async throws -> Operations.AuthDisableMethod.Output
    public var disableAuthMethodAction: DisableAuthMethodSignature?
    public func authDisableMethod(
        _ input: Operations.AuthDisableMethod.Input
    ) async throws -> Operations.AuthDisableMethod.Output {
        guard let block = disableAuthMethodAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias ReadAuthMethodSignature = @Sendable (Operations.AuthReadMethod.Input) async throws -> Operations.AuthReadMethod.Output
    public var readAuthMethodAction: ReadAuthMethodSignature?
    public func authReadMethod(
        _ input: Operations.AuthReadMethod.Input
    ) async throws -> Operations.AuthReadMethod.Output {
        guard let block = readAuthMethodAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}

public struct UnspecifiedBlockError: Swift.Error, LocalizedError, CustomStringConvertible {
    public var function: StaticString

    public var description: String { "Unspecified block for \(function)" }

    public var errorDescription: String? { description }

    public init(function: StaticString = #function) {
        self.function = function
    }
}
