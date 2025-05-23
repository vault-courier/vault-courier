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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

public struct KeyValueResponse<T: Decodable & Sendable>: Sendable {
    public let requestID: String

    /// Key-Value secret data
    public let data: T
}

extension Components.Schemas.WriteSecretResponse {
    var metadata: KeyValueMetadata {
        .init(requestID: requestId,
              createdAt: data.createdTime,
              custom: data.customMetadata?.additionalProperties,
              deletedAt: data.deletionTime,
              isDestroyed: data.destroyed,
              version: data.version)
    }
}

extension Components.Schemas.ReadSecretResponse {
    func secret<T: Decodable & Sendable>() throws -> KeyValueResponse<T> {
        let data = try JSONEncoder().encode(self.data.data)
        let secret = try JSONDecoder().decode(T.self, from: data)
        return .init(requestID: requestId,
                     data: secret)
    }
}

