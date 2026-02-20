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

public enum RSASignatureAlgorithm: Sendable {
    case pss(SaltLength)
    case pkcs1v15

    public var rawValue: String {
        switch self {
            case .pss: "pss"
            case .pkcs1v15: "pkcs1v15"
        }
    }

    public enum SaltLength: Sendable {
        /// The default used by Golang (causing the salt to be as large as possible when signing)
        case auto

        ///  Causes the salt length to equal the length of the hash used in the signature
        case hash

        case count(Int)

        public var rawValue: String {
            switch self {
                case .auto: "auto"
                case .hash: "hash"
                case .count(let int): "\(int)"
            }
        }
    }

}

public enum MarshalingAlgorithm: String, Sendable {
    /// Used by OpenSSL and X.509
    case asn1

    /// The version used by JWS (and thus for JWTs). Selecting this will also change the output encoding to URL-safe Base64 encoding instead of standard Base64-encoding.
    case jws
}

public enum VerificationType: Sendable {
    case signature(String)
    case hmac(String)
}

#endif
