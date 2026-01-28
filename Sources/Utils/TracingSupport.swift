//===----------------------------------------------------------------------===//
//  Copyright (c) 2025-2026 Javier Cuesta
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

import Tracing
#if canImport(FoundationEssentials)
import FoundationEssentials
import FoundationInternationalization
#else
import protocol Foundation.LocalizedError
#endif

// MARK: - Centralized span attribute handling

package struct TracingSupport {
    /// Span attribute keys for the VaultClient
    package struct AttributeKeys: Sendable {
        package static let requestMethod: String = "http.request.method"
        package static let responseStatusCode: String = "http.status_code"
        package static let vaultNamespace: String = "vault.namespace"
        package static let vaultRequestID: String = "vault.request.id"
        package static let vaultAuthMethod: String = "vault.auth.method"
        package static let databasePlugin: String = "vault.database"


        package init() {}
    }

    static package func handleResponse(
        error: some Error,
        _ span: some Span,
        _ statusCode: Int? = nil
    ) {
        if let statusCode {
            span.attributes[AttributeKeys.responseStatusCode] = SpanAttribute.int64(Int64(statusCode))
        }

        span.setStatus(.init(code: .error))
        span.recordError(error)
    }

    static package func handleVaultResponse(
        requestID: String,
        _ span: some Span,
        _ statusCode: Int? = nil
    ) {
        if let statusCode {
            span.attributes[AttributeKeys.responseStatusCode] = SpanAttribute.int64(Int64(statusCode))
        }

        span.attributes[AttributeKeys.vaultRequestID] = requestID
    }
}
