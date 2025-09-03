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

extension VaultClient {
    /// Enables authentication mount. Example AppRole, Token...
    /// - Parameter configuration: Authentication method configuration
    public func enableAuthMethod(configuration: EnableAuthMethodConfig) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.enableAuthMethod(configuration: configuration)
        }
    }

    /// This endpoints returns the configuration of the auth method
    /// - Parameter path: mount path of authentication method
    /// - Returns: Configuration of Authentication Method
    public func readAuthMethodConfiguration(_ path: String) async throws -> ReadAuthMethodResponse {
        try await withSystemBackend { systemBackend in
            try await systemBackend.readAuthMethodConfiguration(path)
        }
    }

    /// Disables authentication method at given path
    /// - Parameter path: mount path of authentication method
    public func disableAuthMethod(_ path: String) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.disableAuthMethod(path)
        }
    }
}
