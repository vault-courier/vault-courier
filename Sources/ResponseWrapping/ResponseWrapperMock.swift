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

package struct ResponseWrapperMock: APIProtocol {
    package init(wrapAction: WrapSignature? = nil, unwrapAction: UnwrapSignature? = nil) {
        self.wrapAction = wrapAction
        self.unwrapAction = unwrapAction
    }

    package typealias WrapSignature = @Sendable (Operations.Wrap.Input) async throws -> Operations.Wrap.Output
    package var wrapAction: WrapSignature?
    package func wrap(_ input: Operations.Wrap.Input) async throws -> Operations.Wrap.Output {
        guard let block = wrapAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias UnwrapSignature = @Sendable (Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output
    package var unwrapAction: UnwrapSignature?
    package func unwrap(_ input: Operations.Unwrap.Input) async throws -> Operations.Unwrap.Output {
        guard let block = unwrapAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
