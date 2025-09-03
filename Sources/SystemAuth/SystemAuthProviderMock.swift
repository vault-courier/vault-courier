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

package struct SystemAuthProviderMock: APIProtocol {
    package init(disableAuthMethodAction: DisableAuthMethodSignature? = nil,
                 enableAuthMethodAction: EnableAuthMethodSignature? = nil,
                 readAuthMethodAction: ReadAuthMethodSignature? = nil) {
        self.disableAuthMethodAction = disableAuthMethodAction
        self.enableAuthMethodAction = enableAuthMethodAction
        self.readAuthMethodAction = readAuthMethodAction
    }

    package typealias DisableAuthMethodSignature = @Sendable (Operations.AuthDisableMethod.Input) async throws -> Operations.AuthDisableMethod.Output
    package var disableAuthMethodAction: DisableAuthMethodSignature?
    package func authDisableMethod(_ input: Operations.AuthDisableMethod.Input) async throws -> Operations.AuthDisableMethod.Output {
        guard let block = disableAuthMethodAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias EnableAuthMethodSignature = @Sendable (Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output
    package var enableAuthMethodAction: EnableAuthMethodSignature?
    package func authEnableMethod(_ input: Operations.AuthEnableMethod.Input) async throws -> Operations.AuthEnableMethod.Output {
        guard let block = enableAuthMethodAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias ReadAuthMethodSignature = @Sendable (Operations.AuthReadMethod.Input) async throws -> Operations.AuthReadMethod.Output
    package var readAuthMethodAction: ReadAuthMethodSignature?
    package func authReadMethod(_ input: Operations.AuthReadMethod.Input) async throws -> Operations.AuthReadMethod.Output {
        guard let block = readAuthMethodAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
