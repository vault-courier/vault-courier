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

/// Database secret engine client
package final class DatabaseEngine: Sendable {
    package struct Configuration: Sendable {
        /// Vault's base URL, e.g. `http://127.0.0.1:8200/v1`
        public let apiURL: URL

        /// Mount path to secret engine
        public let mountPath: String

        public init(apiURL: URL,
                    mountPath: String) {
            self.apiURL = apiURL
            self.mountPath = mountPath
        }
    }

    package init(configuration: Configuration,
                 clientTransport: any ClientTransport,
                 middlewares: [any ClientMiddleware] = [],
                 token: String? = nil) {
        self.client = Client(
            serverURL: configuration.apiURL,
            transport: clientTransport,
            middlewares: middlewares
        )
        self.apiRUL = configuration.apiURL
        self.mountPath = configuration.mountPath
        self._token = .init(token)
    }

    package let apiRUL: URL

    /// The relative mount path, e.g. "database"
    package let mountPath: String

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
