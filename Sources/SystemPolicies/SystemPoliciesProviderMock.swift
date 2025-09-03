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

package struct SystemPoliciesProviderMock: APIProtocol {
    
    package typealias WritePolicySignature = @Sendable (Operations.PoliciesWriteAclPolicy.Input) async throws -> Operations.PoliciesWriteAclPolicy.Output
    package var writePolicyAction: WritePolicySignature?
    package func policiesWriteAclPolicy(_ input: Operations.PoliciesWriteAclPolicy.Input) async throws -> Operations.PoliciesWriteAclPolicy.Output {
        guard let block = writePolicyAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

}
