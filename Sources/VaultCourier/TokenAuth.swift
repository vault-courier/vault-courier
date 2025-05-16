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

extension VaultClient {

    public func createToken(
        _ capabilities: CreateVaultToken,
        wrappTTL: Duration? = nil
    ) async throws -> VaultTokenResponse {
        let sessionToken = try sessionToken()

        let response = try await client.tokenCreate(
            headers: .init(xVaultToken: sessionToken, xVaultWrapTTL: wrappTTL?.formatted(.vaultSeconds)),
            body: .json(.init(
                displayName: capabilities.displayName,
                entityAlias: capabilities.entityAlias,
                explicitMaxTtl: capabilities.tokenMaxTTL?.formatted(.vaultSeconds),
                id: capabilities.id,
                meta: .init(unvalidatedValue: capabilities.meta ?? [:]),
                noDefaultPolicy: !capabilities.hasDefaultPolicy,
                noParent: !capabilities.hasParent,
                numUses: capabilities.tokenNumberOfUses,
                period: capabilities.tokenPeriod,
                policies: capabilities.policies,
                renewable: capabilities.isRenewable,
                ttl: capabilities.ttl?.formatted(.vaultSeconds),
                _type: capabilities.type?.rawValue)
            )
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return VaultTokenResponse(component: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                throw VaultClientError.badRequest(errors)
            case .undocumented(let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                throw VaultClientError.operationFailed(statusCode)
        }
    }
}
