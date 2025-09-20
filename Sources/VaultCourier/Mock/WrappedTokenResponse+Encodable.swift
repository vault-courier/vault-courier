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

#if MockSupport
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Date
#endif

extension WrappedTokenResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case wrapInfo = "wrap_info"
    }

    enum WrapInfoKeys: String, CodingKey {
        case token
        case accessor
        case ttl
        case creationTime = "creation_time"
        case creationPath = "creation_path"
        case wrappedAccessor = "wrapped_accessor"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requestID, forKey: .requestID)

        var wrapInfo = container.nestedContainer(keyedBy: WrapInfoKeys.self, forKey: .wrapInfo)
        try wrapInfo.encode(token, forKey: .token)
        try wrapInfo.encode(accessor, forKey: .accessor)
        try wrapInfo.encode(timeToLive, forKey: .ttl)
        try wrapInfo.encode(createdAt, forKey: .creationTime)
        try wrapInfo.encode(creationPath, forKey: .creationPath)
        try wrapInfo.encode(wrappedAccessor, forKey: .wrappedAccessor)
    }
}

extension WrappedTokenResponse {
    public init(requestID: String,
                token: String,
                accessor: String,
                timeToLive: Int,
                createdAt: Date,
                creationPath: String,
                wrappedAccessor: String) {
        self.requestID = requestID
        self.token = token
        self.accessor = accessor
        self.timeToLive = timeToLive
        self.createdAt = createdAt
        self.creationPath = creationPath
        self.wrappedAccessor = wrappedAccessor
    }
}
#endif


