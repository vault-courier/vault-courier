//===----------------------------------------------------------------------===//
//  Copyright (c) 2026 Javier Cuesta
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

#if TransitEngineSupport
import Testing
import VaultCourier

extension VaultClient {
    @TaskLocal static var secretEngine: EnableSecretMountConfig = EnableSecretMountConfig(mountType: "kv", path: "custom_kv")
}

struct SecretEngineTrait: SuiteTrait, TestScoping {
    let type: String
    let mountPath: String

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let vaultClient = VaultClient.current
        let mountConfig = EnableSecretMountConfig(mountType: type, path: mountPath)
        try await vaultClient.enableSecretEngine(mountConfig: mountConfig)
        
        try await VaultClient.$secretEngine.withValue(mountConfig) {
            try await function()
        }

        try await vaultClient.disableSecretEngine(path: mountPath)
    }
}

extension SuiteTrait where Self == SecretEngineTrait {
    static func setupSecretEngine(
        type: String,
        mountPath: String
    ) -> Self {
        return Self(type: type, mountPath: mountPath)
    }
}
#endif
