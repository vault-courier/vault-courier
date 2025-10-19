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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

extension IntegrationTests.SecretEngine.KeyValue {
    
    static var enginePath: String { "secret" }

    @Test
    func write_and_read_kv_secret() async throws {
        struct Secret: Codable {
            var apiKey: String
        }
        let key = "dev-secret"
        let secret = Secret(apiKey: "abcde12345")

        let vaultClient = VaultClient.current

        // MUT
        let response = try await vaultClient.writeKeyValue(
            mountPath: Self.enginePath,
            secret: secret,
            key: key
        )
        let version = response.version
        #expect(version > 0)

        let readResponse: Secret = try #require(
            try await vaultClient.readKeyValueSecret(
                mountPath: Self.enginePath,
                key: key,
                version: version
            )
        )

        #expect(readResponse.apiKey == secret.apiKey)

        try await vaultClient.delete(mountPath: Self.enginePath, key: key)
        await #expect(throws: VaultServerError.self) {
            let _: Secret? = try await vaultClient.readKeyValueSecret(mountPath: Self.enginePath, key: key)
        }
    }

    @Test
    func write_and_patch_kv_secret() async throws {
        struct Secret: Codable {
            var apiKey: String
        }
        let key = "qa-secret"
        let secret = Secret(apiKey: "abcde")

        let vaultClient = VaultClient.current
        try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: secret, key: key)

        // MUT
        try await vaultClient.patchKeyValue(mountPath: Self.enginePath, secret: Secret(apiKey: "abcde12345"), key: key)
    }

    @Test
    func read_subkeys_kv_secret() async throws {
        struct DbCredentials: Codable {
            var username: String
            var password: String
        }
        struct Secret: Codable {
            var apiKey: String
            var database: Database
            struct Database: Codable {
                var credentials: DbCredentials
            }
        }
        let key = "op-secret"
        let secret = Secret(apiKey: "abcde", database: .init(credentials: .init(username: "test_username", password: "test_password")))

        let vaultClient = VaultClient.current
        try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: secret, key: key)

        // MUT
        _ = try #require(try await vaultClient.readSecretSubkeys(mountPath: Self.enginePath, key: key))
    }

    @Test
    func metadata() async throws {
        let sut = VaultClient.current
        await #expect(throws: VaultServerError.self) {
            try await sut.readMetadata(mountPath: Self.enginePath, key: "non-existent")
        }

        struct Secret: Codable {
            var apiKey: String
        }
        let key = "us-west"
        let secret = Secret(apiKey: "abcde")
        try await sut.writeKeyValue(mountPath: Self.enginePath, secret: secret, key: key)


        _ = try await sut.readMetadata(mountPath: Self.enginePath, key: key)
        let customMetadata = ["deployment": "stage"]
        try await sut.writeMetadata(mountPath: Self.enginePath, key: key, customMetadata: customMetadata)

        let metadata = try await sut.readMetadata(mountPath: Self.enginePath, key: key)
        #expect(metadata.custom == customMetadata)
    }

    @Test
    func deleting_all_metadata_deletes_secret_data_and_history() async throws {
        let sut = VaultClient.current
        await #expect(throws: VaultServerError.self) {
            try await sut.readMetadata(mountPath: Self.enginePath, key: "non-existent")
        }

        struct Secret: Codable {
            var apiKey: String
        }
        let key = "eu-central"
        let secret = Secret(apiKey: "abcde")
        try await sut.writeKeyValue(mountPath: Self.enginePath, secret: secret, key: key)


        _ = try await sut.readMetadata(mountPath: Self.enginePath, key: key)
        let customMetadata = ["deployment": "stage"]
        try await sut.writeMetadata(mountPath: Self.enginePath, key: key, customMetadata: customMetadata)

        // MUT
        try await sut.deleteAllMetadata(mountPath: Self.enginePath, key: key)

        await #expect(throws: VaultServerError.self) {
            let _ : KeyValueResponse<Secret> = try await sut.readKeyValueSecret(mountPath: Self.enginePath, key: key)
        }
    }

    @Test
    func secrets_must_dictionaries_or_codable_objects() async throws {
        let vaultClient = VaultClient.current

        await #expect(throws: VaultClientError.self) {
            // MUT
            _ = try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: "secret", key: "key")
        }

        await #expect(throws: VaultClientError.self) {
            // MUT
            _ = try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: 42, key: "key")
        }

        await #expect(throws: VaultClientError.self) {
            // MUT
            _ = try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: 3.1416, key: "key")
        }

        await #expect(throws: VaultClientError.self) {
            // MUT
            _ = try await vaultClient.writeKeyValue(mountPath: Self.enginePath, secret: true, key: "key")
        }
    }
}
