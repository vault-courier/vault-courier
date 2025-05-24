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

import Testing

import VaultCourier

extension IntegrationTests.Auth.Token {
    @Test
    func crud_token() async throws {
        let vaultClient = VaultClient.current

        let displayName = "admin_token"
        let leaseDuration = 3600
        let policies = ["web", "stage"]
        var tokenID = ""
        await #expect(throws: Never.self) {
            let response = try await vaultClient.createToken(
                .init(policies: policies,
                      meta: ["user": "Juan"],
                      hasParent: false,
                      hasDefaultPolicy: true,
                      ttl: .seconds(leaseDuration),
                      type: .service,
                      tokenMaxTTL: .seconds(60*60*4),
                      displayName: displayName,
                      tokenNumberOfUses: nil)
            )
            tokenID = response.clientToken
            #expect(tokenID.isEmpty == false)

            #expect(response.isOrphan)
            #expect(response.numberOfUses == 0)
            #expect(Set(response.tokenPolicies) == Set(["default"] + policies))
            #expect(response.leaseDuration == .seconds(leaseDuration))

            let renewTTL = Duration.seconds(60)
            let renewResponse = try await vaultClient.renewToken(response.clientToken, by: renewTTL)
            #expect(renewResponse.leaseDuration == renewTTL)

            _ = try await vaultClient.lookup(token: tokenID)

            try await vaultClient.revoke(token: tokenID)
        }

        await #expect(throws: VaultClientError.self) {
            _ = try await vaultClient.lookup(token: tokenID)
        }
    }

    @Test
    func crud_token_role() async throws {
        let vaultClient = VaultClient.current

        let displayName = "dev_token"
        let leaseDuration = 3600
        let policies = ["web", "stage"]
        let roleName = "nomad"
        await #expect(throws: Never.self) {
            let write = try await vaultClient.createToken(
                .init(roleName: roleName,
                      policies: policies,
                      meta: ["user": "Juan"],
                      hasParent: true,
                      hasDefaultPolicy: true,
                      ttl: .seconds(leaseDuration),
                      type: .service,
                      tokenMaxTTL: .seconds(60*60*4),
                      displayName: displayName,
                      tokenNumberOfUses: nil)
            )
            #expect(write.isOrphan == false)

            try await vaultClient.updateTokenRole(
                .init(roleName: roleName,
                      orphan: true,
                      noDefaultPolicy: false)
            )

            let read = try await vaultClient.readTokenRole(name: roleName)
            #expect(read.orphan == true)
            #expect(read.noDefaultPolicy == false)

            try await vaultClient.deleteTokenRole(name: roleName)
        }

        await #expect(throws: VaultClientError.self) {
            _ = try await vaultClient.readTokenRole(name: roleName)
        }
    }
}
