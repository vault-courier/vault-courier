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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif
import Synchronization

package final class TokenAuth: Sendable {
    public init(apiURL: URL,
                clientTransport: any ClientTransport,
                middlewares: [any ClientMiddleware] = [],
                token: String? = nil) {
        self.client = Client(
            serverURL: apiURL,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            transport: clientTransport,
            middlewares: middlewares
        )
        self.basePath = URL(string: "/token", relativeTo: apiURL.appending(path: "auth"))!
        self._token = .init(token)
    }

    package let basePath: URL

    package let client: any APIProtocol

    package let _token: Mutex<String?>

    public var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock { token in
                token = newValue
            }
        }
    }
}
