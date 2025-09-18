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

package struct TokenAuthMock: APIProtocol {
    package var token: String

    package init(token: String,
                 tokenCreateAction: TokenCreateSignature? = nil,
                 lookupTokenAction: LookupTokenSignature? = nil,
                 lookupTokenAccessorAction: LookupTokenAccessorSignature? = nil,
                 lookupTokenSelfAction: LookupTokenSelfSignature? = nil,
                 tokenRenewAction: TokenRenewSignature? = nil,
                 tokenRenewAccessorAction: TokenRenewAccessorSignature? = nil,
                 tokenRenewSelfAction: TokenRenewSelfSignature? = nil,
                 tokenRevokeAccessorAction: TokenRevokeAccessorSignature? = nil,
                 tokenRevokeSelfAction: TokenRevokeSelfSignature? = nil,
                 tokenRevokeAction: TokenRevokeSignature? = nil,
                 tokenRevokeOrphanAction: TokenRevokeOrphanSignature? = nil,
                 updateTokenRoleAction: UpdateTokenRoleSignature? = nil,
                 readTokenRoleAction: ReadTokenRoleSignature? = nil,
                 deleteTokenRoleAction: DeleteTokenRoleSignature? = nil) {
        self.token = token
        self.tokenCreateAction = tokenCreateAction
        self.lookupTokenAction = lookupTokenAction
        self.lookupTokenAccessorAction = lookupTokenAccessorAction
        self.lookupTokenSelfAction = lookupTokenSelfAction
        self.tokenRenewAction = tokenRenewAction
        self.tokenRenewAccessorAction = tokenRenewAccessorAction
        self.tokenRenewSelfAction = tokenRenewSelfAction
        self.tokenRevokeAccessorAction = tokenRevokeAccessorAction
        self.tokenRevokeSelfAction = tokenRevokeSelfAction
        self.tokenRevokeAction = tokenRevokeAction
        self.tokenRevokeOrphanAction = tokenRevokeOrphanAction
        self.updateTokenRoleAction = updateTokenRoleAction
        self.readTokenRoleAction = readTokenRoleAction
        self.deleteTokenRoleAction = deleteTokenRoleAction
    }

    package typealias TokenCreateSignature = @Sendable (Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output
    package var tokenCreateAction: TokenCreateSignature?
    package func tokenCreate(_ input: Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output {
        guard let block = tokenCreateAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias LookupTokenSignature = @Sendable (Operations.LookupToken.Input) async throws -> Operations.LookupToken.Output
    package var lookupTokenAction: LookupTokenSignature?
    package func lookupToken(
        _ input: Operations.LookupToken.Input
    ) async throws -> Operations.LookupToken.Output {
        guard let block = lookupTokenAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias LookupTokenAccessorSignature = @Sendable (Operations.LookupTokenAccessor.Input) async throws -> Operations.LookupTokenAccessor.Output
    package var lookupTokenAccessorAction: LookupTokenAccessorSignature?
    package func lookupTokenAccessor(
        _ input: Operations.LookupTokenAccessor.Input
    ) async throws -> Operations.LookupTokenAccessor.Output {
        guard let block = lookupTokenAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias LookupTokenSelfSignature = @Sendable (Operations.LookupTokenSelf.Input) async throws -> Operations.LookupTokenSelf.Output
    package var lookupTokenSelfAction: LookupTokenSelfSignature?
    package func lookupTokenSelf(
        _ input: Operations.LookupTokenSelf.Input
    ) async throws -> Operations.LookupTokenSelf.Output {
        guard let block = lookupTokenSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRenewSignature = @Sendable (Operations.TokenRenew.Input) async throws -> Operations.TokenRenew.Output
    package var tokenRenewAction: TokenRenewSignature?
    package func tokenRenew(
        _ input: Operations.TokenRenew.Input
    ) async throws -> Operations.TokenRenew.Output {
        guard let block = tokenRenewAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRenewAccessorSignature = @Sendable (Operations.TokenRenewAccessor.Input) async throws -> Operations.TokenRenewAccessor.Output
    package var tokenRenewAccessorAction: TokenRenewAccessorSignature?
    package func tokenRenewAccessor(
        _ input: Operations.TokenRenewAccessor.Input
    ) async throws -> Operations.TokenRenewAccessor.Output {
        guard let block = tokenRenewAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRenewSelfSignature = @Sendable (Operations.TokenRenewSelf.Input) async throws -> Operations.TokenRenewSelf.Output
    package var tokenRenewSelfAction: TokenRenewSelfSignature?
    package func tokenRenewSelf(
        _ input: Operations.TokenRenewSelf.Input
    ) async throws -> Operations.TokenRenewSelf.Output {
        guard let block = tokenRenewSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRevokeAccessorSignature = @Sendable (Operations.TokenRevokeAccessor.Input) async throws -> Operations.TokenRevokeAccessor.Output
    package var tokenRevokeAccessorAction: TokenRevokeAccessorSignature?
    package func tokenRevokeAccessor(
        _ input: Operations.TokenRevokeAccessor.Input
    ) async throws -> Operations.TokenRevokeAccessor.Output {
        guard let block = tokenRevokeAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRevokeSelfSignature = @Sendable (Operations.TokenRevokeSelf.Input) async throws -> Operations.TokenRevokeSelf.Output
    package var tokenRevokeSelfAction: TokenRevokeSelfSignature?
    package func tokenRevokeSelf(
        _ input: Operations.TokenRevokeSelf.Input
    ) async throws -> Operations.TokenRevokeSelf.Output {
        guard let block = tokenRevokeSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRevokeSignature = @Sendable (Operations.TokenRevoke.Input) async throws -> Operations.TokenRevoke.Output
    package var tokenRevokeAction: TokenRevokeSignature?
    package func tokenRevoke(
        _ input: Operations.TokenRevoke.Input
    ) async throws -> Operations.TokenRevoke.Output {
        guard let block = tokenRevokeAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias TokenRevokeOrphanSignature = @Sendable (Operations.TokenRevokeOrphan.Input) async throws -> Operations.TokenRevokeOrphan.Output
    package var tokenRevokeOrphanAction: TokenRevokeOrphanSignature?
    package func tokenRevokeOrphan(
        _ input: Operations.TokenRevokeOrphan.Input
    ) async throws -> Operations.TokenRevokeOrphan.Output {
        guard let block = tokenRevokeOrphanAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias UpdateTokenRoleSignature = @Sendable (Operations.UpdateTokenRole.Input) async throws -> Operations.UpdateTokenRole.Output
    package var updateTokenRoleAction: UpdateTokenRoleSignature?
    package func updateTokenRole(
        _ input: Operations.UpdateTokenRole.Input
    ) async throws -> Operations.UpdateTokenRole.Output {
        guard let block = updateTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias ReadTokenRoleSignature = @Sendable (Operations.ReadTokenRole.Input) async throws -> Operations.ReadTokenRole.Output
    package var readTokenRoleAction: ReadTokenRoleSignature?
    package func readTokenRole(
        _ input: Operations.ReadTokenRole.Input
    ) async throws -> Operations.ReadTokenRole.Output {
        guard let block = readTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    package typealias DeleteTokenRoleSignature = @Sendable (Operations.DeleteTokenRole.Input) async throws -> Operations.DeleteTokenRole.Output
    package var deleteTokenRoleAction: DeleteTokenRoleSignature?
    package func deleteTokenRole(
        _ input: Operations.DeleteTokenRole.Input
    ) async throws -> Operations.DeleteTokenRole.Output {
        guard let block = deleteTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
