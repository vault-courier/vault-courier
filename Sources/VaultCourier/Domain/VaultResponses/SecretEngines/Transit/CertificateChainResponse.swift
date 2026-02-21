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

/// Signed CSR
public struct CertificateChainResponse: Sendable {
    /// Vault's request ID
    public let requestID: String

    /// Certificate Signing Request
    public let certificateChain: String

    /// Name of the key
    public let name: String

    /// Type of encryption key
    public let type: EncryptionKey.KeyType
}

#endif
