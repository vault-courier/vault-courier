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
#if DatabaseEngineSupport
extension RoleCredentialsResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case data
    }

    enum DataKeys: String, CodingKey {
        case username
        case password
        case timeToLive = "ttl"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requestID, forKey: .requestID)

        var auth = container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try auth.encode(username, forKey: .username)
        try auth.encode(password, forKey: .password)
        try auth.encodeIfPresent(timeToLive?.components.seconds, forKey: .timeToLive)
    }
}

extension RoleCredentialsResponse {
    public init(requestID: String,
                username: String,
                password: String,
                timeToLive: Duration) {
        self.requestID = requestID
        self.username = username
        self.password = password
        self.timeToLive = timeToLive
    }
}
#endif
#endif
