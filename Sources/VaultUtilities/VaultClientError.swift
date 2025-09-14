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

public struct VaultClientError: Error, Sendable {
    public var message: String

    package static func invalidState(_ state: String) -> VaultClientError {
        .init(message: "Invalid state: \(state)")
    }

    package static func invalidArgument(_ error: String) -> VaultClientError {
        .init(message: "Invalid argument: \(error)")
    }

    package static func permissionDenied() -> VaultClientError {
        .init(message: "Permission denied")
    }

    package static func decodingFailed() -> VaultClientError {
        .init(message: "Decoding failed")
    }

    package static func receivedUnexpectedResponse(_ message: String? = nil,
                                           file: String = #filePath) -> VaultClientError {
        .init(message: "Received unexpected response. Do you mind filling a bug at https://github.com/vault-courier/vault-courier/issues 🙏?")
    }

    package static func clientIsNotLoggedIn() -> VaultClientError {
        .init(message: "Vault client has not authenticated")
    }

    package static func invalidSecretType() -> VaultClientError {
        .init(message: "KV secret type must be a Dictionary or object of Codable type")
    }

    package static func invalidRole(statements: [String]) -> VaultClientError {
        .init(message: "Invalid role statements: \(statements.joined(separator: ", "))")
    }

    package static func badRequest(_ errors: [String]) -> VaultClientError {
        let errorsDescription = errors.isEmpty ? "" : ": " + errors.joined(separator: ", ")
        return .init(message: "Vault returned a bad request\(errorsDescription)")
    }

    package static func internalServerError(_ errors: [String]) -> VaultClientError {
        let errorsDescription = errors.isEmpty ? "" : ": " + errors.joined(separator: ", ")
        return .init(message: "Internal server error\(errorsDescription)")
    }

    package static func operationFailed(_ statusCode: Int) -> VaultClientError {
        .init(message: "operation failed with \(statusCode)")
    }

    package init(message: String) {
        self.message = message
    }
}
