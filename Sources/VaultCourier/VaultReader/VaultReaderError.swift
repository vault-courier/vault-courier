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

#if PklSupport || ConfigProviderSupport
/// Vault resource reader error
/// 
/// ## Package traits
///
/// This type is guarded by the `PklSupport` or `ConfigProviderSupport` package trait.
///
public struct VaultReaderError: Error, Sendable {
    public var message: String

    static func readingConfigurationFailed() -> VaultClientError {
        .init(message: "Reading module failed")
    }

    static func invalidKeyValueURL(_ relativePath: String) -> VaultClientError {
        .init(message: "Invalid key-value relative path: \(relativePath).")
    }

    static func invalidDatabaseCredential(path: String) -> VaultClientError {
        .init(message: "Invalid database credential path: \(path).")
    }

    static func readingUnsupportedEngine(_ relativePath: String) -> VaultClientError {
        .init(message: "Reading unsupported vault engine or path: \(relativePath).")
    }

    static func readingUnsupportedDatabaseEndpoint(_ relativePath: String) -> VaultClientError {
        .init(message: "Reading unsupported database endpoint: \(relativePath)")
    }
}
#endif
