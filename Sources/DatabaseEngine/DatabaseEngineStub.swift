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

package struct DatabaseEngineMock: APIProtocol {
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

    
//    package typealias ConfigKvSecretsSignature = @Sendable (Operations.ConfigKvSecrets.Input) async throws -> Operations.ConfigKvSecrets.Output
//    package var configKvSecretsAction: ConfigKvSecretsSignature?
//    package func configKvSecrets(
//        _ input: Operations.ConfigKvSecrets.Input
//    ) async throws -> Operations.ConfigKvSecrets.Output {
//        guard let block = configKvSecretsAction
//        else { throw UnspecifiedBlockError() }
//
//        return try await block(input)
//    }

}
