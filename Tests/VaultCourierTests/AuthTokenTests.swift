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

@testable import VaultCourier

extension IntegrationTests.Auth.Token {
    @Test
    func create_and_renew_token() async throws {
        let vaultClient = VaultClient.current

        let displayName = "admin_token"
        let leaseDuration = 3600
        let policies = ["web", "stage"]
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

            #expect(response.isOrphan)
            #expect(response.numberOfUses == 0)
            #expect(Set(response.tokenPolicies) == Set(["default"] + policies))
            #expect(response.leaseDuration == leaseDuration)

            let renewTTL = 60
            let renewResponse = try await vaultClient.renewToken(response.clientToken, by: .seconds(renewTTL))

            #expect(renewResponse.leaseDuration == renewTTL)
        }
    }
}
