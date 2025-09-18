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
import Logging
import SystemWrapping
import SystemAuth
import SystemPolicies
import SystemMounts

/// The `SystemBackend` is the client for all Vault endpoints under `/sys`.
/// This client is used to configure Vault and interact with many of Vault's internal features.
public final class SystemBackend: Sendable {
    static var loggingDisabled: Logger { .init(label: "sys-backend-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    package init(apiURL: URL,
                 clientTransport: any ClientTransport,
                 middlewares: [any ClientMiddleware] = [],
                 token: String? = nil,
                 logger: Logger? = nil) {
        self.wrapping = SystemWrapProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token
        )
        self.auth = SystemAuthProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token
        )
        self.policies = SystemPoliciesProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token
        )
        self.mounts = SystemMountsProvider(
            apiURL: apiURL,
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token
        )
        self.apiURL = apiURL
        self._token = .init(token)
        self.logger = logger ?? Self.loggingDisabled
    }

    /// Vault's URL
    let apiURL: URL

    let wrapping: SystemWrapProvider
    let auth: SystemAuthProvider
    let policies: SystemPoliciesProvider
    let mounts: SystemMountsProvider

    let _token: Mutex<String?>

    /// Client token
    var token: String? {
        get {
            _token.withLock { $0 }
        }
        set {
            _token.withLock {
                $0 = newValue
            }
        }
    }

    let logger: Logging.Logger
}
