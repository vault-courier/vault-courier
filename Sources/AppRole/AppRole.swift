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

/// AppRole Authentication client
package final class AppRoleAuth: Sendable {
    package struct Configuration: Sendable {
        /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        public let apiURL: URL

        /// Custom AppRole authentication path in Vault. Defaults to `approle` when set to `nil`.
        public let mountPath: String

        public init(apiURL: URL,
                    mountPath: String? = nil) {
            self.apiURL = apiURL
            self.mountPath = mountPath ?? "approle"
        }
    }

    package init(configuration: Configuration,
                 clientTransport: any ClientTransport,
                 middlewares: [any ClientMiddleware] = [],
                 token: String? = nil,
                 credentials: AppRoleCredentials? = nil) {
        self.client = Client(
            serverURL: configuration.apiURL,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            transport: clientTransport,
            middlewares: middlewares
        )
        self.basePath = .init(string: configuration.mountPath, relativeTo: configuration.apiURL.appending(path: "auth")) ??  URL(string: "/approle", relativeTo: configuration.apiURL.appending(path: "auth"))!
        self._token = .init(token)
        self._credentials = .init(credentials)
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

    package let _credentials: Mutex<AppRoleCredentials?>
    package var credentials: AppRoleCredentials? {
        get {
            _credentials.withLock { $0 }
        }
        set {
            _credentials.withLock { token in
                token = newValue
            }
        }
    }
}
