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

//import Utils

/// Stub client for local development
//public struct MockClient: APIProtocol {
//
//    public init() {}
//
//    // MARK: KV Secret
//
//    public typealias ConfigKvSecretsSignature = @Sendable (Operations.ConfigKvSecrets.Input) async throws -> Operations.ConfigKvSecrets.Output
//    public var configKvSecretsAction: ConfigKvSecretsSignature?
//    public func configKvSecrets(
//        _ input: Operations.ConfigKvSecrets.Input
//    ) async throws -> Operations.ConfigKvSecrets.Output {
//        guard let block = configKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias ReadKvSecretsConfigSignature = @Sendable (Operations.ReadKvSecretsConfig.Input) async throws -> Operations.ReadKvSecretsConfig.Output
//    public var readKvSecretsConfigAction: ReadKvSecretsConfigSignature?
//    public func readKvSecretsConfig(
//        _ input: Operations.ReadKvSecretsConfig.Input
//    ) async throws -> Operations.ReadKvSecretsConfig.Output {
//        guard let block = readKvSecretsConfigAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias WriteKvSecretsSignature = @Sendable (Operations.WriteKvSecrets.Input) async throws -> Operations.WriteKvSecrets.Output
//    public var writeKvSecretsAction: WriteKvSecretsSignature?
//    public func writeKvSecrets(
//        _ input: Operations.WriteKvSecrets.Input
//    ) async throws -> Operations.WriteKvSecrets.Output {
//        guard let block = writeKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias ReadKvSecretsSignature = @Sendable (Operations.ReadKvSecrets.Input) async throws -> Operations.ReadKvSecrets.Output
//    public var readKvSecretsAction: ReadKvSecretsSignature?
//    public func readKvSecrets(
//        _ input: Operations.ReadKvSecrets.Input
//    ) async throws -> Operations.ReadKvSecrets.Output {
//        guard let block = readKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias PatchKvSecretsSignature = @Sendable (Operations.PatchKvSecrets.Input) async throws -> Operations.PatchKvSecrets.Output
//    public var patchKvSecretsAction: PatchKvSecretsSignature?
//    public func patchKvSecrets(
//        _ input: Operations.PatchKvSecrets.Input
//    ) async throws -> Operations.PatchKvSecrets.Output {
//        guard let block = patchKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias SubkeysKvSecretsSignature = @Sendable (Operations.SubkeysKvSecrets.Input) async throws -> Operations.SubkeysKvSecrets.Output
//    public var subkeysKvSecretsAction: SubkeysKvSecretsSignature?
//    public func subkeysKvSecrets(
//        _ input: Operations.SubkeysKvSecrets.Input
//    ) async throws -> Operations.SubkeysKvSecrets.Output {
//        guard let block = subkeysKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DeleteKvSecretsSignature = @Sendable (Operations.DeleteKvSecrets.Input) async throws -> Operations.DeleteKvSecrets.Output
//    public var deleteKvSecretsAction: DeleteKvSecretsSignature?
//    public func deleteKvSecrets(
//        _ input: Operations.DeleteKvSecrets.Input
//    ) async throws -> Operations.DeleteKvSecrets.Output {
//        guard let block = deleteKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias UndeleteKvSecretsSignature = @Sendable (Operations.UndeleteKvSecrets.Input) async throws -> Operations.UndeleteKvSecrets.Output
//    public var undeleteKvSecretsAction: UndeleteKvSecretsSignature?
//    public func undeleteKvSecrets(
//        _ input: Operations.UndeleteKvSecrets.Input
//    ) async throws -> Operations.UndeleteKvSecrets.Output {
//        guard let block = undeleteKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DestroyKvSecretsSignature = @Sendable (Operations.DestroyKvSecrets.Input) async throws -> Operations.DestroyKvSecrets.Output
//    public var destroyKvSecretsAction: DestroyKvSecretsSignature?
//    public func destroyKvSecrets(
//        _ input: Operations.DestroyKvSecrets.Input
//    ) async throws -> Operations.DestroyKvSecrets.Output {
//        guard let block = destroyKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DeleteLatestKvSecretsSignature = @Sendable (Operations.DeleteLatestKvSecrets.Input) async throws -> Operations.DeleteLatestKvSecrets.Output
//    public var deleteLatestKvSecretsAction: DeleteLatestKvSecretsSignature?
//    public func deleteLatestKvSecrets(
//        _ input: Operations.DeleteLatestKvSecrets.Input
//    ) async throws -> Operations.DeleteLatestKvSecrets.Output {
//        guard let block = deleteLatestKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias ReadMetadataKvSecretsSignature = @Sendable (Operations.ReadMetadataKvSecrets.Input) async throws -> Operations.ReadMetadataKvSecrets.Output
//    public var readMetadataKvSecretsAction: ReadMetadataKvSecretsSignature?
//    public func readMetadataKvSecrets(
//        _ input: Operations.ReadMetadataKvSecrets.Input
//    ) async throws -> Operations.ReadMetadataKvSecrets.Output {
//        guard let block = readMetadataKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias UpdateMetadataKvSecretsSignature = @Sendable (Operations.UpdateMetadataKvSecrets.Input) async throws -> Operations.UpdateMetadataKvSecrets.Output
//    public var updateMetadataKvSecretsAction: UpdateMetadataKvSecretsSignature?
//    public func updateMetadataKvSecrets(
//        _ input: Operations.UpdateMetadataKvSecrets.Input
//    ) async throws -> Operations.UpdateMetadataKvSecrets.Output {
//        guard let block = updateMetadataKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DeleteMetadataKvSecretsSignature = @Sendable (Operations.DeleteMetadataKvSecrets.Input) async throws -> Operations.DeleteMetadataKvSecrets.Output
//    public var deleteMetadataKvSecretsAction: DeleteMetadataKvSecretsSignature?
//    public func deleteMetadataKvSecrets(
//        _ input: Operations.DeleteMetadataKvSecrets.Input
//    ) async throws -> Operations.DeleteMetadataKvSecrets.Output {
//        guard let block = deleteMetadataKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Configure Database Connection
//    public typealias ConfigureDatabaseSignature = @Sendable (Operations.ConfigureDatabase.Input) async throws -> Operations.ConfigureDatabase.Output
//    public var configureDatabaseAction: ConfigureDatabaseSignature?
//    public func configureDatabase(
//        _ input: Operations.ConfigureDatabase.Input
//    ) async throws -> Operations.ConfigureDatabase.Output {
//        guard let block = configureDatabaseAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Read Database Connection
//    public typealias ReadDatabaseConfigurationSignature = @Sendable (Operations.ReadDatabaseConfiguration.Input) async throws -> Operations.ReadDatabaseConfiguration.Output
//    public var readDatabaseConfigurationAction: ReadDatabaseConfigurationSignature?
//    public func readDatabaseConfiguration(
//        _ input: Operations.ReadDatabaseConfiguration.Input
//    ) async throws -> Operations.ReadDatabaseConfiguration.Output {
//        guard let block = readDatabaseConfigurationAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Delete Database Connection
//    public typealias DeleteDatabaseConnectionSignature = @Sendable (Operations.DeleteDatabaseConnection.Input) async throws -> Operations.DeleteDatabaseConnection.Output
//    public var deleteDatabaseConnectionAction: DeleteDatabaseConnectionSignature?
//    public func deleteDatabaseConnection(
//        _ input: Operations.DeleteDatabaseConnection.Input
//    ) async throws -> Operations.DeleteDatabaseConnection.Output {
//        guard let block = deleteDatabaseConnectionAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Reset Database Connection
//    public typealias DatabaseResetSignature = @Sendable (Operations.DatabaseReset.Input) async throws -> Operations.DatabaseReset.Output
//    public var databaseResetAction: DatabaseResetSignature?
//    public func databaseReset(
//        _ input: Operations.DatabaseReset.Input
//    ) async throws -> Operations.DatabaseReset.Output {
//        guard let block = databaseResetAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Reload Database Plugin
//    public typealias ReloadDatabasePluginSignature = @Sendable (Operations.ReloadDatabasePlugin.Input) async throws -> Operations.ReloadDatabasePlugin.Output
//    public var reloadDatabasePluginAction: ReloadDatabasePluginSignature?
//    public func reloadDatabasePlugin(
//        _ input: Operations.ReloadDatabasePlugin.Input
//    ) async throws -> Operations.ReloadDatabasePlugin.Output {
//        guard let block = reloadDatabasePluginAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Rotate Vault Root Database Password
//    public typealias DatabaseRotateRootSignature = @Sendable (Operations.DatabaseRotateRoot.Input) async throws -> Operations.DatabaseRotateRoot.Output
//    public var databaseRotateRootAction: DatabaseRotateRootSignature?
//    public func databaseRotateRoot(
//        _ input: Operations.DatabaseRotateRoot.Input
//    ) async throws -> Operations.DatabaseRotateRoot.Output {
//        guard let block = databaseRotateRootAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Read Static Role Credentials
//    public typealias DatabaseReadStaticRoleCredentialsSignature = @Sendable (Operations.DatabaseReadStaticRoleCredentials.Input) async throws -> Operations.DatabaseReadStaticRoleCredentials.Output
//    public var databaseReadStaticRoleCredentialsAction: DatabaseReadStaticRoleCredentialsSignature?
//    public func databaseReadStaticRoleCredentials(
//        _ input: Operations.DatabaseReadStaticRoleCredentials.Input
//    ) async throws -> Operations.DatabaseReadStaticRoleCredentials.Output {
//        guard let block = databaseReadStaticRoleCredentialsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Read Database Static Role
//    public typealias DatabaseReadStaticRoleSignature = @Sendable (Operations.DatabaseReadStaticRole.Input) async throws -> Operations.DatabaseReadStaticRole.Output
//    public var databaseReadStaticRoleAction: DatabaseReadStaticRoleSignature?
//    public func databaseReadStaticRole(
//        _ input: Operations.DatabaseReadStaticRole.Input
//    ) async throws -> Operations.DatabaseReadStaticRole.Output {
//        guard let block = databaseReadStaticRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Delete Database Static Role
//    public typealias DatabaseDeleteStaticRoleSignature = @Sendable (Operations.DatabaseDeleteStaticRole.Input) async throws -> Operations.DatabaseDeleteStaticRole.Output
//    public var databaseDeleteStaticRoleAction: DatabaseDeleteStaticRoleSignature?
//    public func databaseDeleteStaticRole(
//        _ input: Operations.DatabaseDeleteStaticRole.Input
//    ) async throws -> Operations.DatabaseDeleteStaticRole.Output {
//        guard let block = databaseDeleteStaticRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Create Database Static Role
//    public typealias DatabaseCreateStaticRoleSignature = @Sendable (Operations.DatabaseCreateStaticRole.Input) async throws -> Operations.DatabaseCreateStaticRole.Output
//    public var databaseCreateStaticRoleAction: DatabaseCreateStaticRoleSignature?
//    public func databaseCreateStaticRole(
//        _ input: Operations.DatabaseCreateStaticRole.Input
//    ) async throws -> Operations.DatabaseCreateStaticRole.Output {
//        guard let block = databaseCreateStaticRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Read Role Credentials
//    public typealias DatabaseReadRoleCredentialsSignature = @Sendable (Operations.DatabaseReadRoleCredentials.Input) async throws -> Operations.DatabaseReadRoleCredentials.Output
//    public var databaseReadRoleCredentialsAction: DatabaseReadRoleCredentialsSignature?
//    public func databaseReadRoleCredentials(
//        _ input: Operations.DatabaseReadRoleCredentials.Input
//    ) async throws -> Operations.DatabaseReadRoleCredentials.Output {
//        guard let block = databaseReadRoleCredentialsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Delete Database Role
//    public typealias DatabaseDeleteRoleSignature = @Sendable (Operations.DatabaseDeleteRole.Input) async throws -> Operations.DatabaseDeleteRole.Output
//    public var databaseDeleteRoleAction: DatabaseDeleteRoleSignature?
//    public func databaseDeleteRole(
//        _ input: Operations.DatabaseDeleteRole.Input
//    ) async throws -> Operations.DatabaseDeleteRole.Output {
//        guard let block = databaseDeleteRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Create Database Role
//    public typealias DatabaseCreateRoleSignature = @Sendable (Operations.DatabaseCreateRole.Input) async throws -> Operations.DatabaseCreateRole.Output
//    public var databaseCreateRoleAction: DatabaseCreateRoleSignature?
//    public func databaseCreateRole(
//        _ input: Operations.DatabaseCreateRole.Input
//    ) async throws -> Operations.DatabaseCreateRole.Output {
//        guard let block = databaseCreateRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Read Database Role
//    public typealias DatabaseReadRoleSignature = @Sendable (Operations.DatabaseReadRole.Input) async throws -> Operations.DatabaseReadRole.Output
//    public var databaseReadRoleAction: DatabaseReadRoleSignature?
//    public func databaseReadRole(
//        _ input: Operations.DatabaseReadRole.Input
//    ) async throws -> Operations.DatabaseReadRole.Output {
//        guard let block = databaseReadRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Policy
//    public typealias WriteAclPolicySignature = @Sendable (Operations.PoliciesWriteAclPolicy.Input) async throws -> Operations.PoliciesWriteAclPolicy.Output
//    public var writeAclPolicyAction: WriteAclPolicySignature?
//    public func policiesWriteAclPolicy(
//        _ input: Operations.PoliciesWriteAclPolicy.Input
//    ) async throws -> Operations.PoliciesWriteAclPolicy.Output {
//        guard let block = writeAclPolicyAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias EnableSecretsEngineSignature
//        = @Sendable (Operations.MountsEnableSecretsEngine.Input) async throws -> Operations.MountsEnableSecretsEngine.Output
//    public var enableSecretsEngineAction: EnableSecretsEngineSignature?
//    public func mountsEnableSecretsEngine(
//        _ input: Operations.MountsEnableSecretsEngine.Input
//    ) async throws -> Operations.MountsEnableSecretsEngine.Output {
//        guard let block = enableSecretsEngineAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//
//
//    // MARK: AppRole
//
//    public typealias AuthReadApproleSecretIdWithAccessorSignature
//        = @Sendable (Operations.AuthReadApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output
//    public var authReadApproleSecretIdWithAccessorAction: AuthReadApproleSecretIdWithAccessorSignature?
//    public func authReadApproleSecretIdWithAccessor(
//        _ input: Operations.AuthReadApproleSecretIdWithAccessor.Input
//    ) async throws -> Operations.AuthReadApproleSecretIdWithAccessor.Output {
//        guard let block = authReadApproleSecretIdWithAccessorAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias AuthDestroyApproleSecretIdWithAccessorSignature
//        = @Sendable (Operations.AuthDestroyApproleSecretIdWithAccessor.Input) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output
//    public var authDestroyApproleSecretIdWithAccessorAction: AuthDestroyApproleSecretIdWithAccessorSignature?
//    public func authDestroyApproleSecretIdWithAccessor(
//        _ input: Operations.AuthDestroyApproleSecretIdWithAccessor.Input
//    ) async throws -> Operations.AuthDestroyApproleSecretIdWithAccessor.Output {
//        guard let block = authDestroyApproleSecretIdWithAccessorAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias AuthApproleLoginSignature = @Sendable (Operations.AuthApproleLogin.Input) async throws -> Operations.AuthApproleLogin.Output
//    public var authApproleLoginAction: AuthApproleLoginSignature?
//    public func authApproleLogin(
//        _ input: Operations.AuthApproleLogin.Input
//    ) async throws -> Operations.AuthApproleLogin.Output {
//        guard let block = authApproleLoginAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: TokenAuth
//
//    public typealias TokenCreateSignature = @Sendable (Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output
//    public var tokenCreateAction: TokenCreateSignature?
//    public func tokenCreate(_ input: Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output {
//        guard let block = tokenCreateAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias LookupTokenSignature = @Sendable (Operations.LookupToken.Input) async throws -> Operations.LookupToken.Output
//    public var lookupTokenAction: LookupTokenSignature?
//    public func lookupToken(
//        _ input: Operations.LookupToken.Input
//    ) async throws -> Operations.LookupToken.Output {
//        guard let block = lookupTokenAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias LookupTokenAccessorSignature = @Sendable (Operations.LookupTokenAccessor.Input) async throws -> Operations.LookupTokenAccessor.Output
//    public var lookupTokenAccessorAction: LookupTokenAccessorSignature?
//    public func lookupTokenAccessor(
//        _ input: Operations.LookupTokenAccessor.Input
//    ) async throws -> Operations.LookupTokenAccessor.Output {
//        guard let block = lookupTokenAccessorAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias LookupTokenSelfSignature = @Sendable (Operations.LookupTokenSelf.Input) async throws -> Operations.LookupTokenSelf.Output
//    public var lookupTokenSelfAction: LookupTokenSelfSignature?
//    public func lookupTokenSelf(
//        _ input: Operations.LookupTokenSelf.Input
//    ) async throws -> Operations.LookupTokenSelf.Output {
//        guard let block = lookupTokenSelfAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRenewSignature = @Sendable (Operations.TokenRenew.Input) async throws -> Operations.TokenRenew.Output
//    public var tokenRenewAction: TokenRenewSignature?
//    public func tokenRenew(
//        _ input: Operations.TokenRenew.Input
//    ) async throws -> Operations.TokenRenew.Output {
//        guard let block = tokenRenewAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRenewAccessorSignature = @Sendable (Operations.TokenRenewAccessor.Input) async throws -> Operations.TokenRenewAccessor.Output
//    public var tokenRenewAccessorAction: TokenRenewAccessorSignature?
//    public func tokenRenewAccessor(
//        _ input: Operations.TokenRenewAccessor.Input
//    ) async throws -> Operations.TokenRenewAccessor.Output {
//        guard let block = tokenRenewAccessorAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRenewSelfSignature = @Sendable (Operations.TokenRenewSelf.Input) async throws -> Operations.TokenRenewSelf.Output
//    public var tokenRenewSelfAction: TokenRenewSelfSignature?
//    public func tokenRenewSelf(
//        _ input: Operations.TokenRenewSelf.Input
//    ) async throws -> Operations.TokenRenewSelf.Output {
//        guard let block = tokenRenewSelfAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRevokeAccessorSignature = @Sendable (Operations.TokenRevokeAccessor.Input) async throws -> Operations.TokenRevokeAccessor.Output
//    public var tokenRevokeAccessorAction: TokenRevokeAccessorSignature?
//    public func tokenRevokeAccessor(
//        _ input: Operations.TokenRevokeAccessor.Input
//    ) async throws -> Operations.TokenRevokeAccessor.Output {
//        guard let block = tokenRevokeAccessorAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRevokeSelfSignature = @Sendable (Operations.TokenRevokeSelf.Input) async throws -> Operations.TokenRevokeSelf.Output
//    public var tokenRevokeSelfAction: TokenRevokeSelfSignature?
//    public func tokenRevokeSelf(
//        _ input: Operations.TokenRevokeSelf.Input
//    ) async throws -> Operations.TokenRevokeSelf.Output {
//        guard let block = tokenRevokeSelfAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRevokeSignature = @Sendable (Operations.TokenRevoke.Input) async throws -> Operations.TokenRevoke.Output
//    public var tokenRevokeAction: TokenRevokeSignature?
//    public func tokenRevoke(
//        _ input: Operations.TokenRevoke.Input
//    ) async throws -> Operations.TokenRevoke.Output {
//        guard let block = tokenRevokeAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias TokenRevokeOrphanSignature = @Sendable (Operations.TokenRevokeOrphan.Input) async throws -> Operations.TokenRevokeOrphan.Output
//    public var tokenRevokeOrphanAction: TokenRevokeOrphanSignature?
//    public func tokenRevokeOrphan(
//        _ input: Operations.TokenRevokeOrphan.Input
//    ) async throws -> Operations.TokenRevokeOrphan.Output {
//        guard let block = tokenRevokeOrphanAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias UpdateTokenRoleSignature = @Sendable (Operations.UpdateTokenRole.Input) async throws -> Operations.UpdateTokenRole.Output
//    public var updateTokenRoleAction: UpdateTokenRoleSignature?
//    public func updateTokenRole(
//        _ input: Operations.UpdateTokenRole.Input
//    ) async throws -> Operations.UpdateTokenRole.Output {
//        guard let block = updateTokenRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias ReadTokenRoleSignature = @Sendable (Operations.ReadTokenRole.Input) async throws -> Operations.ReadTokenRole.Output
//    public var readTokenRoleAction: ReadTokenRoleSignature?
//    public func readTokenRole(
//        _ input: Operations.ReadTokenRole.Input
//    ) async throws -> Operations.ReadTokenRole.Output {
//        guard let block = readTokenRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DeleteTokenRoleSignature = @Sendable (Operations.DeleteTokenRole.Input) async throws -> Operations.DeleteTokenRole.Output
//    public var deleteTokenRoleAction: DeleteTokenRoleSignature?
//    public func deleteTokenRole(
//        _ input: Operations.DeleteTokenRole.Input
//    ) async throws -> Operations.DeleteTokenRole.Output {
//        guard let block = deleteTokenRoleAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: Wrapping
//    public typealias UnwrapSignature = @Sendable (Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output
//    public var unwrapAction: UnwrapSignature?
//    public func unwrap(_ input: Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output {
//        guard let block = unwrapAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    // MARK: SystemAuth
//
//    public typealias EnableAuthSignature = @Sendable (Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output
//    public var enableAuthAction: EnableAuthSignature?
//    public func authEnableMethod(_ input: Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output {
//        guard let block = enableAuthAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias DisableAuthMethodSignature = @Sendable (Operations.AuthDisableMethod.Input) async throws -> Operations.AuthDisableMethod.Output
//    public var disableAuthMethodAction: DisableAuthMethodSignature?
//    public func authDisableMethod(
//        _ input: Operations.AuthDisableMethod.Input
//    ) async throws -> Operations.AuthDisableMethod.Output {
//        guard let block = disableAuthMethodAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//
//    public typealias ReadAuthMethodSignature = @Sendable (Operations.AuthReadMethod.Input) async throws -> Operations.AuthReadMethod.Output
//    public var readAuthMethodAction: ReadAuthMethodSignature?
//    public func authReadMethod(
//        _ input: Operations.AuthReadMethod.Input
//    ) async throws -> Operations.AuthReadMethod.Output {
//        guard let block = readAuthMethodAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }
//}

//public struct UnspecifiedBlockError: Swift.Error, LocalizedError, CustomStringConvertible {
//    public var function: StaticString
//
//    public var description: String { "Unspecified block for \(function)" }
//
//    public var errorDescription: String? { description }
//
//    public init(function: StaticString = #function) {
//        self.function = function
//    }
//}

//package struct UnspecifiedBlockError: Swift.Error, LocalizedError, CustomStringConvertible {
//    public var function: StaticString
//
//    public var description: String { "Unspecified block for \(function)" }
//
//    public var errorDescription: String? { description }
//
//    public init(function: StaticString = #function) {
//        self.function = function
//    }
//}
