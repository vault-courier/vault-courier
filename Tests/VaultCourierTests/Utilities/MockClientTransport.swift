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


import XCTest
import HTTPTypes
import Foundation
import OpenAPIRuntime

struct MockClientTransport: ClientTransport {
    var sendBlock: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (
        HTTPResponse, HTTPBody?
    ) { try await sendBlock(request, body, baseURL, operationID) }

    static let requestBody: HTTPBody = HTTPBody("hello")
    static let responseBody: HTTPBody = HTTPBody("bye")

    static var successful: Self { MockClientTransport { _, _, _, _ in (HTTPResponse(status: .ok), responseBody) } }

    static var failing: Self { MockClientTransport { _, _, _, _ in throw TestError() } }
}

struct TestError: Error, Equatable {}

extension HTTPRequest {
    var normalizedPath: String? {
        self.path?.replacingOccurrences(of: "%2F", with: "/")
    }
}
