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

public struct EncryptionResponse: Sendable {
    public let requestID: String
    
    public let ciphertext: String

    public let plaintext: String?

    /// Key version
    public let version: Int?

    package init(
        requestID: String,
        ciphertext: String,
        plaintext: String? = nil,
        version: Int?
    ) {
        self.requestID = requestID
        self.ciphertext = ciphertext
        self.plaintext = plaintext
        self.version = version
    }
}

public struct DecryptionResponse: Sendable {
    public let requestID: String

    public let plaintext: String
}

#endif
