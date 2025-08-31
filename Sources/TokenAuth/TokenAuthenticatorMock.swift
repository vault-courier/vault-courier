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

public struct TokenAuthenticatorMock: APIProtocol {
    public var token: String

    public init(token: String,
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

    public typealias TokenCreateSignature = @Sendable (Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output
    public var tokenCreateAction: TokenCreateSignature?
    public func tokenCreate(_ input: Operations.TokenCreate.Input) async throws -> Operations.TokenCreate.Output {
        guard let block = tokenCreateAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias LookupTokenSignature = @Sendable (Operations.LookupToken.Input) async throws -> Operations.LookupToken.Output
    public var lookupTokenAction: LookupTokenSignature?
    public func lookupToken(
        _ input: Operations.LookupToken.Input
    ) async throws -> Operations.LookupToken.Output {
        guard let block = lookupTokenAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias LookupTokenAccessorSignature = @Sendable (Operations.LookupTokenAccessor.Input) async throws -> Operations.LookupTokenAccessor.Output
    public var lookupTokenAccessorAction: LookupTokenAccessorSignature?
    public func lookupTokenAccessor(
        _ input: Operations.LookupTokenAccessor.Input
    ) async throws -> Operations.LookupTokenAccessor.Output {
        guard let block = lookupTokenAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias LookupTokenSelfSignature = @Sendable (Operations.LookupTokenSelf.Input) async throws -> Operations.LookupTokenSelf.Output
    public var lookupTokenSelfAction: LookupTokenSelfSignature?
    public func lookupTokenSelf(
        _ input: Operations.LookupTokenSelf.Input
    ) async throws -> Operations.LookupTokenSelf.Output {
        guard let block = lookupTokenSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRenewSignature = @Sendable (Operations.TokenRenew.Input) async throws -> Operations.TokenRenew.Output
    public var tokenRenewAction: TokenRenewSignature?
    public func tokenRenew(
        _ input: Operations.TokenRenew.Input
    ) async throws -> Operations.TokenRenew.Output {
        guard let block = tokenRenewAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRenewAccessorSignature = @Sendable (Operations.TokenRenewAccessor.Input) async throws -> Operations.TokenRenewAccessor.Output
    public var tokenRenewAccessorAction: TokenRenewAccessorSignature?
    public func tokenRenewAccessor(
        _ input: Operations.TokenRenewAccessor.Input
    ) async throws -> Operations.TokenRenewAccessor.Output {
        guard let block = tokenRenewAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRenewSelfSignature = @Sendable (Operations.TokenRenewSelf.Input) async throws -> Operations.TokenRenewSelf.Output
    public var tokenRenewSelfAction: TokenRenewSelfSignature?
    public func tokenRenewSelf(
        _ input: Operations.TokenRenewSelf.Input
    ) async throws -> Operations.TokenRenewSelf.Output {
        guard let block = tokenRenewSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRevokeAccessorSignature = @Sendable (Operations.TokenRevokeAccessor.Input) async throws -> Operations.TokenRevokeAccessor.Output
    public var tokenRevokeAccessorAction: TokenRevokeAccessorSignature?
    public func tokenRevokeAccessor(
        _ input: Operations.TokenRevokeAccessor.Input
    ) async throws -> Operations.TokenRevokeAccessor.Output {
        guard let block = tokenRevokeAccessorAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRevokeSelfSignature = @Sendable (Operations.TokenRevokeSelf.Input) async throws -> Operations.TokenRevokeSelf.Output
    public var tokenRevokeSelfAction: TokenRevokeSelfSignature?
    public func tokenRevokeSelf(
        _ input: Operations.TokenRevokeSelf.Input
    ) async throws -> Operations.TokenRevokeSelf.Output {
        guard let block = tokenRevokeSelfAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRevokeSignature = @Sendable (Operations.TokenRevoke.Input) async throws -> Operations.TokenRevoke.Output
    public var tokenRevokeAction: TokenRevokeSignature?
    public func tokenRevoke(
        _ input: Operations.TokenRevoke.Input
    ) async throws -> Operations.TokenRevoke.Output {
        guard let block = tokenRevokeAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias TokenRevokeOrphanSignature = @Sendable (Operations.TokenRevokeOrphan.Input) async throws -> Operations.TokenRevokeOrphan.Output
    public var tokenRevokeOrphanAction: TokenRevokeOrphanSignature?
    public func tokenRevokeOrphan(
        _ input: Operations.TokenRevokeOrphan.Input
    ) async throws -> Operations.TokenRevokeOrphan.Output {
        guard let block = tokenRevokeOrphanAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias UpdateTokenRoleSignature = @Sendable (Operations.UpdateTokenRole.Input) async throws -> Operations.UpdateTokenRole.Output
    public var updateTokenRoleAction: UpdateTokenRoleSignature?
    public func updateTokenRole(
        _ input: Operations.UpdateTokenRole.Input
    ) async throws -> Operations.UpdateTokenRole.Output {
        guard let block = updateTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias ReadTokenRoleSignature = @Sendable (Operations.ReadTokenRole.Input) async throws -> Operations.ReadTokenRole.Output
    public var readTokenRoleAction: ReadTokenRoleSignature?
    public func readTokenRole(
        _ input: Operations.ReadTokenRole.Input
    ) async throws -> Operations.ReadTokenRole.Output {
        guard let block = readTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }

    public typealias DeleteTokenRoleSignature = @Sendable (Operations.DeleteTokenRole.Input) async throws -> Operations.DeleteTokenRole.Output
    public var deleteTokenRoleAction: DeleteTokenRoleSignature?
    public func deleteTokenRole(
        _ input: Operations.DeleteTokenRole.Input
    ) async throws -> Operations.DeleteTokenRole.Output {
        guard let block = deleteTokenRoleAction
        else { throw UnspecifiedBlockError() }

        return try await block(input)
    }
}
