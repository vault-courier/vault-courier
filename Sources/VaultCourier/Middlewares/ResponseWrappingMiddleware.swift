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
import HTTPTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

public struct ResponseWrappingMiddleware: ClientMiddleware {
    public var timeToLive: Duration

    public func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        var wrapRequest = request
        wrapRequest.headerFields.append(.init(name: .wrapTTL, value: String(timeToLive.components.seconds)))
        return try await next(wrapRequest, body, baseURL)
    }
}

extension HTTPField.Name {
    static let wrapTTL = Self("X-VAULT-WRAP-TTL")!
}
