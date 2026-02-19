//===----------------------------------------------------------------------===//
//  Copyright (c) 2026 Javier Cuesta
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

#if TransitEngineSupport
import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
import struct Foundation.Date
#endif
import Synchronization
import Logging
import Tracing
import TransitEngine
import Utils

/// Client for Transit secret engine
///
/// - Note: You don't usually create this type directly, but instead use ``VaultClient/withTransitClient(namespace:mountPath:execute:)`` to interact with this type
public final class TransitEngineClient: Sendable {
    static var loggingDisabled: Logger { .init(label: "transit-client-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() }) }

    init(apiURL: URL,
         clientTransport: any ClientTransport,
         namespace: String,
         mountPath: String,
         middlewares: [any ClientMiddleware] = [],
         token: String? = nil,
         logger: Logger? = nil) {
        self.engine = TransitEngine(
            configuration: .init(apiURL: apiURL, namespace: namespace, mountPath: mountPath),
            clientTransport: clientTransport,
            middlewares: middlewares,
            token: token
        )
        self.apiURL = apiURL
        self.namespace = namespace
        self.mountPath = mountPath.removeSlash()
        self._token = .init(token)
        var logger = logger ?? Self.loggingDisabled
        logger[metadataKey: "engine"] = "transit"
        self.logger = logger
    }

    /// Vault's base URL
    let apiURL: URL

    /// Target's namespace
    let namespace: String

    /// Mount path of KeyValue secret engine
    let mountPath: String

    /// Engine client
    let engine: TransitEngine

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

    typealias TracingAttributes = TracingSupport.AttributeKeys
}

extension TransitEngineClient {

    
    public func writeEncryptionKey(
        name: String,
        type: EncryptionKey.KeyType,
        isDerived: DerivedEncryption? = nil,
        isExportable: Bool = false,
        allowPlainTextBackup: Bool = false,
        autoRotatePeriod: Duration? = nil
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.WriteEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let (derived, isConvergentEncryption) = if let isDerived {
                (true, isDerived.isConvergentEncryption)
            } else {
                (false, false)
            }

            let keySize: Int? = if case let .hmac(size) = type { size } else { nil }

            let response = try await engine.client.writeEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    derived: derived,
                    exportable: isExportable,
                    allowPlaintextBackup: allowPlainTextBackup,
                    _type: .init(rawValue: type.rawValue) ?? .aes256Gcm96,
                    autoRotatePeriod: autoRotatePeriod?.formatted(.vaultSeconds) ?? "0",
                    convergentEncryption: isConvergentEncryption,
                    keySize: keySize)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    span.attributes[TracingAttributes.vaultRequestID] = vaultRequestID
                    span.attributes[TracingAttributes.responseStatusCode] = 200
                    let eventName = "encryption key created"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return .init(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func readEncryptionKey(
        name: String
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.ReadEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.readEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read encryption key"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return .init(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func deleteEncryptionKey(
        name: String
    ) async throws {
        return try await withSpan(Operations.ReadEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.deleteEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .noContent:
                    let eventName = "encryption key deleted"
                    span.attributes[TracingAttributes.responseStatusCode] = 204
                    span.addEvent(.init(name: eventName))
                    logger.trace(.init(stringLiteral: eventName))
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func updateKeyConfiguration(
        name: String,
        minDecryptionVersion: Int?,
        minEncryptionVersion: Int? = nil,
        isDeletionAllowed: Bool = false,
        isExportable: Bool = false,
        allowPlaintextBackup: Bool = false,
        autoRotationPeriod: Duration? = nil
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.ConfigEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.configEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    minDecryptionVersion: minDecryptionVersion,
                    minEncryptionVersion: minEncryptionVersion,
                    deletionAllowed: isDeletionAllowed,
                    exportable: isExportable,
                    allowPlaintextBackup: allowPlaintextBackup,
                    autoRotatePeriod: autoRotationPeriod?.formatted(.vaultSeconds))
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "encryption key configuration updated"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return EncryptionKeyResponse(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func rotateEncryptionKey(
        name: String
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.RotateEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.rotateEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "encryption key rotated"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return EncryptionKeyResponse(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Softly deletes a named encryption key, allowing it to be restored later if this deletion was done in error. This doesn't depend on the value of `isDeletionAllowed` on configuration.
    /// The following operations will not work on the key until the key is restored (see ``restoreSoftDeletedKey(name:)``):
    /// 
    /// - Exporting
    /// - Encryption/Decryption
    /// - Signing/Verifying
    /// - Rotating the key
    /// 
    /// However, this key will still be able to be updated, backed up, read
    /// - Parameter name: name of the encryption key
    /// - Returns: encryption key properties
    public func softDeleteKey(
        name: String
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.SoftDeleteEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.softDeleteEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "encryption key soft-deleted"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return EncryptionKeyResponse(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Restores a soft-deleted encryption key
    ///
    /// See ``softDeleteKey(name:)``
    public func restoreSoftDeletedKey(
        name: String
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.RestoreEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.restoreEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "restore soft-deleted key"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return EncryptionKeyResponse(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Configures the automatic creation of unknown keys preventing new keys from being created if none exists.
    /// 
    /// This endpoint maintains global configuration across all keys
    /// - Parameter disable: disable upsert
    /// - Returns: whether upserting is disable
    public func configureUpsert(
        disable: Bool
    ) async throws -> Bool {
        return try await withSpan(Operations.WriteUpsertConfig.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.writeUpsertConfig(
                path: .init(transitPath: enginePath),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(disableUpsert: disable))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    let state = json.data.disableUpsert ? "disabled" : "enabled"

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "upsert is \(state)"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return json.data.disableUpsert
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Reads whether its possible to create new keys if none exists.
    ///
    /// - returns: whether upserting is disable
    public func readUpsertConfig() async throws -> Bool {
        return try await withSpan(Operations.ReadUpsertConfig.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.readUpsertConfig(
                path: .init(transitPath: enginePath),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    let state = json.data.disableUpsert ? "disabled" : "enabled"

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "upsert is \(state)"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return json.data.disableUpsert
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - plaintext: base64 encoded plaintext to be encoded
    ///   - key: `ed25519` is not supported for encryption
    ///   - associatedData: base64 encoded associated data (also known as additional data or AAD) to also be authenticated with AEAD ciphers (`aes128-gcm96`, `aes256-gcm`, `chacha20-poly1305`, and `xchacha20-poly1305`). If given, this value is needed for decryption
    ///   - context: base64 encoded context for key derivation. This is required if key derivation is enabled for this key
    ///   - nonce: base64 encoded nonce value. The value must be exactly 96 bits (12 bytes) long and the user must ensure that for any given context (and thus, any given encryption key) this nonce value is never reused.
    ///   - convergentEncryption: This parameter is only applicable when a key is being created and indicates whether convergent encryption is supported. Convergent encryption is supported only for keys with key derivation enabled and requires all requests to include both a context and a nonce: a 96-bit (12-byte) nonce for AES and ChaCha20, or a 192-bit (24-byte) nonce for XChaCha20. The provided nonce is used instead of a randomly generated one. As a result, supplying the same context and nonce will produce the same ciphertext. When using this mode, it is critical to ensure that nonces are unique for each context. Reusing a nonce within the same context will severely compromise the security of the ciphertext.
    /// - Returns: ciphertext
    public func encrypt(
        plaintext: String,
        key: EncryptionKey,
        associatedData: String? = nil,
        context: String? = nil,
        nonce: String? = nil,
        convergentEncryption: String? = nil
    ) async throws -> EncryptionResponse {
        return try await withSpan(Operations.Encrypt.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            if case .ed25519 = key.type {
                throw VaultClientError.invalidArgument("message encryption not supported for key type \(key.type)")
            }

            let response = try await engine.client.encrypt(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    associatedData: associatedData,
                    context: context,
                    nonce: nonce,
                    batchInput: nil,
                    partialFailureResponseCode: nil,
                    plaintext: plaintext,
                    keyVersion: key.version,
                    _type: .init(rawValue: key.type.rawValue),
                    convergentEncryption: convergentEncryption)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "encryption with key \(key.type)"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return .init(
                        requestID: vaultRequestID,
                        ciphertext: json.data.ciphertext,
                        version: json.data.keyVersion
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Retrieves the wrapping key to use for importing keys
    ///
    /// - Returns: 4096-bit RSA public key
    public func wrappingKey() async throws -> String {
        return try await withSpan(Operations.ReadWrappingKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.readWrappingKey(
                path: .init(transitPath: enginePath),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    logger.trace(
                        .init(stringLiteral: "read wrapping key for importing cryptographic key"),
                        metadata: [
                        TracingAttributes.vaultRequestID: .string(vaultRequestID)
                    ])

                    return json.data.publicKey

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }



    public func importEncryption(
        key: EncryptionKey,
        importedType: EncryptionKey.ImportedType,
        hashFunction: HashFunction = .SHA256,
        derivedContext: DerivedContext? = nil,
        isExportable: Bool = false,
        allowPlainTextBackup: Bool = false,
        autoRotatePeriod: Duration? = nil
    ) async throws -> EncryptionKeyResponse? {
        return try await withSpan(Operations.ImportEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let (derived, context): (Bool, String?) = if let derivedContext {
                (true, derivedContext.value)
            } else {
                (false, nil)
            }

            let ciphertext: String? = if case let .ciphertext(ciphertext) = importedType { ciphertext } else { nil }
            let publicKey: String? = if case let .publicKey(publicKey) = importedType { publicKey } else { nil }

            let response = try await engine.client.importEncryptionKey(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    derived: derived,
                    exportable: isExportable,
                    allowPlaintextBackup: allowPlainTextBackup,
                    _type: .init(rawValue: key.type.rawValue) ?? .aes256Gcm96,
                    autoRotatePeriod: autoRotatePeriod?.formatted(.vaultSeconds) ?? "0",
                    ciphertext: ciphertext,
                    hashFunction: .init(rawValue: hashFunction.rawValue) ?? .sha256,
                    publicKey: publicKey,
                    context: context)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type.rawValue) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type.rawValue))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    span.attributes[TracingAttributes.vaultRequestID] = vaultRequestID
                    span.attributes[TracingAttributes.responseStatusCode] = 200
                    let eventName = "encryption key imported"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.asymmetricKeys

                    return .init(
                        requestID: vaultRequestID,
                        isDerived: json.data.derived,
                        isExportable: json.data.exportable,
                        isPlaintextBackupAllowed: json.data.allowPlaintextBackup,
                        keyType: encryptionKeyType,
                        autoRotatePeriod: Duration.seconds(json.data.autoRotatePeriod),
                        isDeletionAllowed: json.data.deletionAllowed ?? false,
                        isImported: json.data.importedKey ?? false,
                        kdf: json.data.kdf,
                        keys: keys,
                        latestVersion: json.data.latestVersion,
                        minAvailableVersion: json.data.minAvailableVersion ?? 0,
                        minDecryptionVersion: json.data.minDecryptionVersion,
                        minEncryptionVersion: json.data.minEncryptionVersion,
                        name: json.data.name,
                        isSoftDeleted: json.data.softDeleted ?? false,
                        supportsDecryption: json.data.supportsDecryption,
                        supportsEncryption: json.data.supportsEncryption,
                        supportsSigning: json.data.supportsSigning,
                        supportsDerivation: json.data.supportsDerivation
                    )

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Exports a named encryption key from the Vault
    /// - Parameters:
    ///   - key: encryption key
    ///   - format: format of the exported type
    /// - Returns: all versioned encryption keys in the given format
    public func exportEncryption(
        key: EncryptionKey,
        format: EncryptionKey.ExportedType
    ) async throws -> ExportedKeyResponse {
        return try await withSpan(Operations.ExportEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.exportEncryptionKey(
                path: .init(transitPath: enginePath, keyType: key.type.rawValue, name: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(format: .init(rawValue: format.rawValue) ?? .none))
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    guard let encryptionKeyType = EncryptionKey.KeyType(rawValue: json.data._type) else {
                        let clientError = VaultClientError.receivedUnexpectedResponse("unexpected encryption key type: \(String(describing: json.data._type))")
                        TracingSupport.handleResponse(error: clientError, span)
                        throw clientError
                    }

                    let vaultRequestID = json.requestId
                    span.attributes[TracingAttributes.vaultRequestID] = vaultRequestID
                    span.attributes[TracingAttributes.responseStatusCode] = 200
                    let eventName = "encryption key imported"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return .init(
                        requestID: vaultRequestID,
                        keys: json.data.keys.additionalProperties.values.map({$0}),
                        name: json.data.name,
                        type: encryptionKeyType
                    )
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

}

private extension [String: Components.Schemas.WriteEncryptionKeyResponse.DataPayload.KeysPayload.AdditionalPropertiesPayload] {
    var asymmetricKeys: [AsymmetricKeyData] {
        self.values.map({ value in
            switch value {
                case let .case1(asymmetricKeyData):
                    return .init(
                        certificateChain: asymmetricKeyData.certificateChain,
                        createdAt: asymmetricKeyData.creationTime,
                        name: asymmetricKeyData.name,
                        publicKey: asymmetricKeyData.publicKey
                    )
                case let .case2(unixTime):
                    return  .init(
                        certificateChain: nil,
                        createdAt: Date(timeIntervalSince1970: Double(unixTime)),
                        name: nil,
                        publicKey: nil
                    )
            }
        })
    }
}


#endif
