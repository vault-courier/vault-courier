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

package import protocol OpenAPIRuntime.ClientTransport
package import protocol OpenAPIRuntime.ClientMiddleware
#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import struct Foundation.URL
#endif
package import Synchronization

package final class SystemWrapProvider: Sendable {
    package init(apiURL: URL,
                clientTransport: any ClientTransport,
                middlewares: [any ClientMiddleware] = [],
                token: String? = nil) {
        self.client = Client(
            serverURL: apiURL,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            transport: clientTransport,
            middlewares: middlewares
        )
        self.basePath = URL(string: "/wrapping", relativeTo: apiURL.appending(path: "sys"))!
        self._token = .init(token)
    }

    package let basePath: URL

    package let client: any APIProtocol

    package let _token: Mutex<String?>

    package var token: String? {
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
