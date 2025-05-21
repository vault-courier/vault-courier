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

    public let metadata: Metadata?

    public let mountType: String?

    public struct Metadata: Sendable {
        public let createdAt: String

        public let custom: [String:String]?

        public let deletedAt: String?

        public let isDestroyed: Bool?

        public let version: Int
    }
}

public extension KeyValueResponse {
    init?(payload: Components.Schemas.ReadSecretResponse) {
        self.requestID = payload.requestId
        guard let data = try? JSONEncoder().encode(payload.data.data),
              let secret = try? JSONDecoder().decode(T.self, from: data)
        else { return nil }
        self.data = secret
        self.metadata = if let metadata = payload.metadata {
            .init(createdAt: metadata.createdTime,
                  custom: metadata.customMetadata?.additionalProperties,
                  deletedAt: metadata.deletionTime,
                  isDestroyed: metadata.destroyed,
                  version: metadata.version)
        } else {
            nil
        }
        self.mountType = payload.mountType
    }
}

public struct WriteData: Codable, Sendable {
    public let createdTime: String?

    public let customMetadata: [String: String]?

    public let deletionTime: String?

    public let destroyed: Bool?

    public let version: Int?
}

public extension KeyValueResponse<WriteData> {
    init?(payload: Components.Schemas.WriteSecretResponse) {
        self.requestID = payload.requestId
        self.data = .init(createdTime: payload.data.createdTime,
                          customMetadata: payload.data.customMetadata?.additionalProperties,
                          deletionTime: payload.data.deletionTime,
                          destroyed: payload.data.destroyed,
                          version: payload.data.version)
        self.metadata = nil
        self.mountType = payload.mountType
    }
}
