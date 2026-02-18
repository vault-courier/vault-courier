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

public enum EncryptionKey: RawRepresentable, Codable, Sendable {
    case `aes128-gcm96`
    case `aes256-gcm96`
    case `chacha20-poly1305`
    case `xchacha20-poly1305`
    case `ed25519`
    case `ecdsa-p256`
    case `ecdsa-p384`
    case `ecdsa-p521`
    case `rsa-2048`
    case `rsa-3072`
    case `rsa-4096`
    case hmac(size: Int?)

    public var rawValue: String {
        switch self {
            case .`aes128-gcm96`:
                "aes128-gcm96"
            case .`aes256-gcm96`:
                "aes256-gcm96"
            case .`chacha20-poly1305`:
                "chacha20-poly1305"
            case .`xchacha20-poly1305`:
                "xchacha20-poly1305"
            case .ed25519:
                "ed25519"
            case .`ecdsa-p256`:
                "ecdsa-p256"
            case .`ecdsa-p384`:
                "ecdsa-p384"
            case .`ecdsa-p521`:
                "ecdsa-p521"
            case .`rsa-2048`:
                "rsa-2048"
            case .`rsa-3072`:
                "rsa-3072"
            case .`rsa-4096`:
                "rsa-4096"
            case .hmac: "hmac"
        }
    }

    public init?(rawValue: String) {
        if rawValue == "hmac" {
            self = .hmac(size: nil)
            return
        } else if rawValue == "rsa-4096" {
            self = .`rsa-4096`
        } else if rawValue == "rsa-3072" {
            self = .`rsa-3072`
        } else if rawValue == "rsa-2048" {
            self = .`rsa-2048`
        } else if rawValue == "ecdsa-p521" {
            self = .`ecdsa-p521`
        } else if rawValue == "ecdsa-p384" {
            self = .`ecdsa-p384`
        } else if rawValue == "ecdsa-p256" {
            self = .`ecdsa-p256`
        } else if rawValue == "ed25519" {
            self = .`ed25519`
        } else if rawValue == "xchacha20-poly1305" {
            self = .`xchacha20-poly1305`
        } else if rawValue == "chacha20-poly1305" {
            self = .`chacha20-poly1305`
        } else if rawValue == "aes256-gcm96" {
            self = .`aes256-gcm96`
        } else if rawValue == "aes128-gcm96" {
            self = .`aes128-gcm96`
        } else {
            return nil
        }
    }
}


#endif
