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

public enum HashFunction: String, Codable, Sendable {
    case SHA224
    case SHA256
    case SHA384
    case SHA512
}

public enum HashAlgorithm: String, Codable, Sendable {
    case SHA2_224 = "sha2-224"
    case SHA2_384 = "sha2-384"
    case SHA2_512 = "sha2-512"
    case SHA3_256 = "sha3-256"
    case SHA3_384 = "sha3-384"
    case SHA3_512 = "sha3-512"
}

#endif

