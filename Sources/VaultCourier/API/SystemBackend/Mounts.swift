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
    /// Enables secret engine
    /// - Parameter mountConfig: mount configuration including path of secret engine
    public func enableSecretEngine(
        mountConfig: EnableSecretMountConfig
    ) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.enableSecretEngine(mountConfig: mountConfig)
        }
    }

    /// Get configuration for secret engine
    /// - Parameter path: mount path of secret engine
    public func readSecretEngineConfig(path: String) async throws -> SecretEngineConfigResponse {
        try await withSystemBackend { systemBackend in
            try await systemBackend.readSecretEngineConfig(path: path)
        }
    }

    /// Disables secret engine
    /// - Parameter path: mount path to secret engine
    public func disableSecretEngine(path: String) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.disableAuthMethod(path)
        }
    }
}
