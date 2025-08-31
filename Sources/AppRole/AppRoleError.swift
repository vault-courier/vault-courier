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

public struct AppRoleError: Error, Sendable {
    public var message: String

    static func decodingFailed() -> Self {
        .init(message: "Decoding failed")
    }

    static func receivedUnexpectedResponse(_ message: String? = nil,
                                           file: String = #filePath) -> Self {
        .init(message: "Received unexpected response. Do you mind filling a bug at https://github.com/vault-courier/vault-courier/issues 🙏?")
    }

    public static func missingToken() -> Self {
        .init(message: "AppRole client token has not been set")
    }

    public static func missingCredentials() -> Self {
        .init(message: "AppRole credentials have not been set")
    }

    public static func badRequest(_ errors: [String]) -> Self {
        let errorsDescription = errors.isEmpty ? "" : ": " + errors.joined(separator: ", ")
        return .init(message: "Vault returned a bad request \(errorsDescription)")
    }

    public static func internalServerError(_ errors: [String]) -> Self {
        let errorsDescription = errors.isEmpty ? "" : ": " + errors.joined(separator: ", ")
        return .init(message: "Internal server error \(errorsDescription)")
    }

    public static func operationFailed(_ statusCode: Int) -> Self {
        .init(message: "operation failed with \(statusCode)")
    }
}
