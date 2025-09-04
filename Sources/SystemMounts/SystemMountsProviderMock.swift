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

package struct SystemMountsProviderMock: APIProtocol {
    package typealias ReadMountSignature = @Sendable (Operations.MountsReadSecretsEngine.Input) async throws -> Operations.MountsReadSecretsEngine.Output
    package var readMountAction: ReadMountSignature?
    package func mountsReadSecretsEngine(_ input: Operations.MountsReadSecretsEngine.Input) async throws -> Operations.MountsReadSecretsEngine.Output {
        guard let block = readMountAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
    

    package typealias EnableMountSignature = @Sendable (Operations.MountsEnableSecretsEngine.Input) async throws -> Operations.MountsEnableSecretsEngine.Output
    package var enableMountAction: EnableMountSignature?
    package func mountsEnableSecretsEngine(_ input: Operations.MountsEnableSecretsEngine.Input) async throws -> Operations.MountsEnableSecretsEngine.Output {
        guard let block = enableMountAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DisableMountSignature = @Sendable (Operations.MountsDisableSecretsEngine.Input) async throws -> Operations.MountsDisableSecretsEngine.Output
    package var disableMountAction: DisableMountSignature?
    package func mountsDisableSecretsEngine(_ input: Operations.MountsDisableSecretsEngine.Input) async throws -> Operations.MountsDisableSecretsEngine.Output {
        guard let block = disableMountAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
