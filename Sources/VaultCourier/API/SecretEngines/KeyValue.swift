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
import protocol Foundation.LocalizedError
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import protocol Foundation.LocalizedError
#endif

extension VaultClient {
    // MARK: Write

    
    /// Creates a new version of a secret at the specified location. If the value does not yet exist, the calling token must have an ACL policy granting the create capability.
    /// If the value already exists, the calling token must have an ACL policy granting the update capability.
    ///
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - secret: value of the secret
    ///   - key: It's the path of the secret to update
    /// - Returns: Metadata about the secret, like its current version and creation time
    @discardableResult
    public func writeKeyValue(
        enginePath: String? = nil,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueResponse<WriteData>? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await client.writeKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(
                options: .init(cas: nil),
                data: json)))

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(payload: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(let statusCode, let payload):
                if let buffer = try await payload.body?.collect(upTo: 1024, using: .init()) {
                    let error = String(buffer: buffer)
                    logger.debug(.init(stringLiteral: "operation error with body: \(error)"))
                }
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                return nil
        }
    }

    // MARK: Read

    
    /// Retrieves the secret at the specified location.
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: value of the secret
    public func readKeyValueSecret<T: Decodable & Sendable>(
        enginePath: String? = nil,
        key: String,
        version: Int? = nil
    ) async throws -> T? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return try JSONDecoder().decode(T.self, from: data)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
                return nil
        }
    }

    /// Retrieves the secret at the specified location.
    /// - Parameters:
    ///   - enginePath: path to key/value secret engine mount
    ///   - key: It's the path to the secret relative to the secret mount `enginePath`
    ///   - version: Specifies the version to return. If not set the latest version is returned.
    /// - Returns: Data of the secret
    public func readKeyValueSecretData(
        enginePath: String? = nil,
        key: String,
        version: Int? = nil
    ) async throws -> Data? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let response = try await client.readKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            query: .init(version: version),
            headers: .init(xVaultToken: sessionToken)
        )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                let data = try JSONEncoder().encode(json.data.data)
                return data
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(statusCode: let statusCode, _):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode):"))
                return nil
        }
    }

    @discardableResult
    public func patchKeyValue(
        enginePath: String? = nil,
        secret: some Codable,
        key: String
    ) async throws -> KeyValueResponse<WriteData>? {
        let enginePath = enginePath ?? self.mounts.kv.relativePath.removeSlash()
        let sessionToken = try sessionToken()

        let data = try JSONEncoder().encode(secret)
        let json: OpenAPIObjectContainer
        do {
            json = try JSONDecoder().decode(OpenAPIObjectContainer.self, from: data)
        } catch {
            throw VaultClientError.invalidSecretType()
        }

        let response = try await client.patchKvSecrets(
            path: .init(kvPath: enginePath, secretKey: key),
            headers: .init(xVaultToken: sessionToken),
            body: .applicationMergePatchJson(.init(
                options: .init(cas: nil),
                data: json))
            )

        switch response {
            case .ok(let content):
                let json = try content.body.json
                return .init(payload: json)
            case .badRequest(let content):
                let errors = (try? content.body.json.errors) ?? []
                logger.debug("Bad request: \(errors.joined(separator: ", ")).")
                return nil
            case .undocumented(let statusCode, let payload):
                if let buffer = try await payload.body?.collect(upTo: 1024, using: .init()) {
                    let error = String(buffer: buffer)
                    logger.debug(.init(stringLiteral: "operation error with body: \(error)"))
                }
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)"))
                return nil
        }
    }
}
