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

extension IntegrationTests.KeyValue {
    @Test
    func write_and_read_kv_secret() async throws {
        struct Secret: Codable {
            var apiKey: String
        }
        let key = "dev-secret"
        let secret = Secret(apiKey: "abcde12345")

        let vaultClient = VaultClient.current

        // MUT
        let response = try await vaultClient.writeKeyValue(secret: secret, key: key)
        #expect(response?.data.version == 1)

        guard let readResponse: Secret = try await vaultClient.readKeyValueSecret(key: key)
        else {
            Issue.record("Failed to read kv secret")
            return
        }

        #expect(readResponse.apiKey == secret.apiKey)
    }
}
