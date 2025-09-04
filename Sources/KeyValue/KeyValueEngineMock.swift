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

import VaultUtilities

package struct KeyValueEngineMock: APIProtocol {
    package typealias ConfigKvSecretsSignature = @Sendable (Operations.ConfigKvSecrets.Input) async throws -> Operations.ConfigKvSecrets.Output
    package var configKvSecretsAction: ConfigKvSecretsSignature?
    package func configKvSecrets(
        _ input: Operations.ConfigKvSecrets.Input
    ) async throws -> Operations.ConfigKvSecrets.Output {
        guard let block = configKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias ReadKvSecretsConfigSignature = @Sendable (Operations.ReadKvSecretsConfig.Input) async throws -> Operations.ReadKvSecretsConfig.Output
    package var readKvSecretsConfigAction: ReadKvSecretsConfigSignature?
    package func readKvSecretsConfig(
        _ input: Operations.ReadKvSecretsConfig.Input
    ) async throws -> Operations.ReadKvSecretsConfig.Output {
        guard let block = readKvSecretsConfigAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias WriteKvSecretsSignature = @Sendable (Operations.WriteKvSecrets.Input) async throws -> Operations.WriteKvSecrets.Output
    package var writeKvSecretsAction: WriteKvSecretsSignature?
    package func writeKvSecrets(
        _ input: Operations.WriteKvSecrets.Input
    ) async throws -> Operations.WriteKvSecrets.Output {
        guard let block = writeKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias ReadKvSecretsSignature = @Sendable (Operations.ReadKvSecrets.Input) async throws -> Operations.ReadKvSecrets.Output
    package var readKvSecretsAction: ReadKvSecretsSignature?
    package func readKvSecrets(
        _ input: Operations.ReadKvSecrets.Input
    ) async throws -> Operations.ReadKvSecrets.Output {
        guard let block = readKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias PatchKvSecretsSignature = @Sendable (Operations.PatchKvSecrets.Input) async throws -> Operations.PatchKvSecrets.Output
    package var patchKvSecretsAction: PatchKvSecretsSignature?
    package func patchKvSecrets(
        _ input: Operations.PatchKvSecrets.Input
    ) async throws -> Operations.PatchKvSecrets.Output {
        guard let block = patchKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias SubkeysKvSecretsSignature = @Sendable (Operations.SubkeysKvSecrets.Input) async throws -> Operations.SubkeysKvSecrets.Output
    package var subkeysKvSecretsAction: SubkeysKvSecretsSignature?
    package func subkeysKvSecrets(
        _ input: Operations.SubkeysKvSecrets.Input
    ) async throws -> Operations.SubkeysKvSecrets.Output {
        guard let block = subkeysKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DeleteKvSecretsSignature = @Sendable (Operations.DeleteKvSecrets.Input) async throws -> Operations.DeleteKvSecrets.Output
    package var deleteKvSecretsAction: DeleteKvSecretsSignature?
    package func deleteKvSecrets(
        _ input: Operations.DeleteKvSecrets.Input
    ) async throws -> Operations.DeleteKvSecrets.Output {
        guard let block = deleteKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias UndeleteKvSecretsSignature = @Sendable (Operations.UndeleteKvSecrets.Input) async throws -> Operations.UndeleteKvSecrets.Output
    package var undeleteKvSecretsAction: UndeleteKvSecretsSignature?
    package func undeleteKvSecrets(
        _ input: Operations.UndeleteKvSecrets.Input
    ) async throws -> Operations.UndeleteKvSecrets.Output {
        guard let block = undeleteKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DestroyKvSecretsSignature = @Sendable (Operations.DestroyKvSecrets.Input) async throws -> Operations.DestroyKvSecrets.Output
    package var destroyKvSecretsAction: DestroyKvSecretsSignature?
    package func destroyKvSecrets(
        _ input: Operations.DestroyKvSecrets.Input
    ) async throws -> Operations.DestroyKvSecrets.Output {
        guard let block = destroyKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DeleteLatestKvSecretsSignature = @Sendable (Operations.DeleteLatestKvSecrets.Input) async throws -> Operations.DeleteLatestKvSecrets.Output
    package var deleteLatestKvSecretsAction: DeleteLatestKvSecretsSignature?
    package func deleteLatestKvSecrets(
        _ input: Operations.DeleteLatestKvSecrets.Input
    ) async throws -> Operations.DeleteLatestKvSecrets.Output {
        guard let block = deleteLatestKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias ReadMetadataKvSecretsSignature = @Sendable (Operations.ReadMetadataKvSecrets.Input) async throws -> Operations.ReadMetadataKvSecrets.Output
    package var readMetadataKvSecretsAction: ReadMetadataKvSecretsSignature?
    package func readMetadataKvSecrets(
        _ input: Operations.ReadMetadataKvSecrets.Input
    ) async throws -> Operations.ReadMetadataKvSecrets.Output {
        guard let block = readMetadataKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias UpdateMetadataKvSecretsSignature = @Sendable (Operations.UpdateMetadataKvSecrets.Input) async throws -> Operations.UpdateMetadataKvSecrets.Output
    package var updateMetadataKvSecretsAction: UpdateMetadataKvSecretsSignature?
    package func updateMetadataKvSecrets(
        _ input: Operations.UpdateMetadataKvSecrets.Input
    ) async throws -> Operations.UpdateMetadataKvSecrets.Output {
        guard let block = updateMetadataKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DeleteMetadataKvSecretsSignature = @Sendable (Operations.DeleteMetadataKvSecrets.Input) async throws -> Operations.DeleteMetadataKvSecrets.Output
    package var deleteMetadataKvSecretsAction: DeleteMetadataKvSecretsSignature?
    package func deleteMetadataKvSecrets(
        _ input: Operations.DeleteMetadataKvSecrets.Input
    ) async throws -> Operations.DeleteMetadataKvSecrets.Output {
        guard let block = deleteMetadataKvSecretsAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
