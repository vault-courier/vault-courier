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
    /// Creates a new encryption key
    /// - Parameters:
    ///   - name: name of encryption key
    ///   - type: type of encryption key
    ///   - derivedKey: whether is a derived key. Set to `nil` if its not derived. Convergent encryption can be set here.
    ///   - isExportable:  Enables keys to be exportable.
    ///   - allowPlainTextBackup: If set, enables taking backup of named key in the plaintext format. Once set, this cannot be disabled.
    ///   - autoRotatePeriod: The period at which this key should be rotated automatically. Setting to `nil` will disable automatic key rotation.
    /// - Returns: new encryption key
    public func writeEncryptionKey(
        name: String,
        type: EncryptionKey.KeyType,
        derivedKey: DerivedEncryption? = nil,
        isExportable: Bool = false,
        allowPlainTextBackup: Bool = false,
        autoRotatePeriod: Duration? = nil
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.WriteEncryptionKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let (derived, isConvergentEncryption) = if let derivedKey {
                (true, derivedKey.isConvergentEncryption)
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
    
    /// Gets encryption key
    /// - Parameter name: name of the encryption key
    /// - Returns: encryption key
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

    /// Deletes encryption key
    /// - Parameter name: name of the encryption key
    public func deleteEncryptionKey(
        name: String
    ) async throws {
        return try await withSpan(Operations.DeleteEncryptionKey.id, ofKind: .client) { span in
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
    
    /// Updates cryptographic key storage properties
    ///
    /// - Parameters:
    ///   - name: name of the key
    ///   - minDecryptionVersion: minimum decryption version available
    ///   - minEncryptionVersion: minimum encryption version available
    ///   - isDeletionAllowed: whether deletion is enabled
    ///   - isExportable:  Enables keys to be exportable.
    ///   - allowPlainTextBackup: If set, enables taking backup of named key in the plaintext format. Once set, this cannot be disabled.
    ///   - autoRotatePeriod: The period at which this key should be rotated automatically. Setting to `nil` will disable automatic key rotation.
    /// - Returns: encryption key
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
    /// Reverses the action of ``softDeleteKey(name:)``
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
    
    /// Encrypts plaintext using the named key
    ///
    /// - Parameters:
    ///   - plaintext: base64 encoded plaintext to be encoded
    ///   - key: encryption key. `ed25519` is not supported for encryption
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
        convergentEncryption: Bool? = nil
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
                    partialFailureResponseCode: nil,
                    plaintext: plaintext,
                    keyVersion: key.version,
                    _type: .init(rawValue: key.type.rawValue),
                    convergentEncryption: convergentEncryption,
                    batchInput: nil)
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

                    switch json.data {
                        case .case1:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case .case2(let result):
                            return .init(
                                requestID: vaultRequestID,
                                ciphertext: result.ciphertext,
                                version: result.keyVersion
                            )
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Decrypts ciphertext with given named encryption key
    /// - Parameters:
    ///   - ciphertext: ciphertext to decrypt.
    ///   - key: encryption key
    ///   - associatedData: base64 encoded associated data (also known as additional data or AAD) to also be authenticated with AEAD ciphers (`aes128-gcm96`, `aes256-gcm`, `chacha20-poly1305`, and `xchacha20-poly1305`). This is only needed if the encryption used it.
    ///   - context: base64 encoded context for key derivation. This is required if key derivation is enabled for this key
    ///   - nonce: base64 encoded nonce value. The value must be exactly 96 bits (12 bytes) long and the user must ensure that for any given context (and thus, any given encryption key) this nonce value is never reused.
    /// - Returns: decrypted plaintext in base64
    public func decrypt(
        ciphertext: String,
        key: EncryptionKey,
        associatedData: String? = nil,
        context: String? = nil,
        nonce: String? = nil,
    ) async throws -> DecryptionResponse {
        return try await withSpan(Operations.Decrypt.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            if case .ed25519 = key.type {
                throw VaultClientError.invalidArgument("message encryption not supported for key type \(key.type)")
            }

            let response = try await engine.client.decrypt(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    associatedData: associatedData,
                    context: context,
                    nonce: nonce,
                    partialFailureResponseCode: nil,
                    ciphertext: ciphertext,
                    batchInput: nil)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "decryption with key \(key.type)"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    switch json.data {
                        case .case1:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case .case2(let result):
                            return .init(
                                requestID: vaultRequestID,
                                plaintext: result.plaintext
                            )
                    }

                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    public func decryptBatch(
        _ batch: [DecryptionBatchElement],
        key: EncryptionKey,
        partialFailureResponseCode: Int = 400
    ) async throws -> BatchDecryptionResponse {
        return try await withSpan(Operations.Decrypt.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            if case .ed25519 = key.type {
                throw VaultClientError.invalidArgument("message encryption not supported for key type \(key.type)")
            }

            let batchInput: [Operations.Decrypt.Input.Body.JsonPayload.BatchInputPayloadPayload] = batch.map({
                .init(
                    ciphertext: $0.ciphertext,
                    context: $0.derivedKeyContext?.context,
                    reference: $0.reference
                )
            })

            let response = try await engine.client.decrypt(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    associatedData: nil,
                    context: nil,
                    nonce: nil,
                    partialFailureResponseCode: partialFailureResponseCode,
                    ciphertext: "",
                    batchInput: batchInput)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "decryption with key \(key.type)"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    let failureResult = FailureResult(hasPartialFailure: false)
                    switch json.data {
                        case .case1(let batch):
                            let output: [DecryptionBatchOutput] = batch.batchResults.map {  [weak failureResult] result in
                                switch result {
                                    case .case1(let encryption):
                                        return .init(plaintext: encryption.plaintext, reference: encryption.reference)
                                    case .case2(let failure):
                                        failureResult?.hasPartialFailure = true
                                        return .init(plaintext: "", reference: failure.error)
                                }
                            }

                            return .init(
                                requestID: vaultRequestID,
                                hasPartialFailure: failureResult.hasPartialFailure,
                                output: output
                            )
                        case .case2:
                            throw VaultClientError.receivedUnexpectedResponse()
                    }
                case let .undocumented(statusCode, payload):
                    if statusCode == partialFailureResponseCode {
                        let errors: String?
                        if let body = payload.body {
                            let expectedLength: Int? = switch body.length {
                                case let .known(size): Int(size)
                                case .unknown: nil
                            }

                            let data = try await Data(collecting: body, upTo: expectedLength ?? 1024*1024)
                            do {
                                errors = try JSONDecoder().decode(VaultErrorBody.self, from: data).errors.joined(separator: ", ")
                            } catch {
                                errors = nil
                            }
                            if errors == nil {
                                let json = try JSONDecoder().decode(Operations.Decrypt.Output.Ok.Body.JsonPayload.self, from: data)

                                let failureResult = FailureResult(hasPartialFailure: false)
                                switch json.data {
                                    case .case1(let batch):
                                        let output: [DecryptionBatchOutput] = batch.batchResults.map {  [weak failureResult] result in
                                            switch result {
                                                case .case1(let encryption):
                                                    if let error = encryption.error {
                                                        failureResult?.hasPartialFailure = true
                                                        failureResult?.error = error
                                                    }
                                                    return .init(plaintext: encryption.plaintext, reference: encryption.reference)
                                                case .case2(let failure):
                                                    let vaultError = VaultServerError.invalidRequest(errors: failure.error)
                                                    logger.debug(.init(stringLiteral: "Partial failure during batch decryption: \(failure.error)"))
                                                    TracingSupport.handleResponse(error: vaultError, span, statusCode)

                                                    failureResult?.hasPartialFailure = true
                                                    failureResult?.error = failure.error
                                                    return .init(plaintext: "", reference: "")
                                            }
                                        }

                                        let vaultRequestID = json.requestId
                                        if failureResult.hasPartialFailure  {
                                            let message = failureResult.error
                                            let vaultError = VaultServerError.invalidRequest(errors: message)
                                            logger.debug(
                                                .init(stringLiteral: "Partial failure during batch encryption: \(message ?? "<nil>")"),
                                                metadata: [
                                                    TracingAttributes.vaultRequestID: .string(vaultRequestID)
                                                ]
                                            )
                                            TracingSupport.handleResponse(error: vaultError, span, statusCode)
                                        } else {
                                            throw VaultClientError.receivedUnexpectedResponse()
                                        }

                                        return .init(
                                            requestID: json.requestId,
                                            hasPartialFailure: true,
                                            output: output
                                        )
                                    case .case2:
                                        throw VaultClientError.receivedUnexpectedResponse()
                                }
                            }
                        } else {
                            errors = nil
                        }

                        let vaultError = VaultServerError.invalidRequest(errors: errors)
                        logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                        TracingSupport.handleResponse(error: vaultError, span, statusCode)
                        throw vaultError
                    } else {
                        let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                        logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                        TracingSupport.handleResponse(error: vaultError, span, statusCode)
                        throw vaultError
                    }
            }
        }
    }
    
    /// Encrypts batch of plaintexts
    /// - Parameters:
    ///   - batch: encryption batch with optional derived key context
    ///   - key: encryption key
    ///   - convergentEncryption: whether convergent encryption is set
    ///   - partialFailureResponseCode: Ordinarily, if a batch item fails to encrypt due to a bad input, but other batch items succeed, the HTTP response code is 400 (Bad Request).
    ///   Some applications may want to treat partial failures differently. Providing the parameter returns the given response code integer instead of a failed status code in this case.
    ///   If all values fail an error code is still returned.
    ///
    /// - warning: some failures (such as failure to decrypt) could be indicative of a security breach and should not be ignored.
    ///
    /// - Returns: encrypted batch
    public func encryptBatch(
        _ batch: [EncryptionBatchElement],
        key: EncryptionKey,
        convergentEncryption: Bool? = nil,
        partialFailureResponseCode: Int = 400
    ) async throws -> BatchEncryptionResponse {
        return try await withSpan(Operations.Encrypt.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            if case .ed25519 = key.type {
                throw VaultClientError.invalidArgument("message encryption not supported for key type \(key.type)")
            }
            let batchInput: [Operations.Encrypt.Input.Body.JsonPayload.BatchInputPayloadPayload] = batch.map({
                .init(
                    plaintext: $0.plaintext,
                    context: $0.derivedKeyContext?.context,
                    reference: $0.reference
                )
            })
            let response = try await engine.client.encrypt(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    associatedData: nil,
                    context: nil,
                    nonce: nil,
                    partialFailureResponseCode: partialFailureResponseCode,
                    plaintext: "",
                    keyVersion: key.version,
                    _type: .init(rawValue: key.type.rawValue),
                    convergentEncryption: convergentEncryption,
                    batchInput: batchInput)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json
                    let vaultRequestID = json.requestId

                    let failureResult = FailureResult(hasPartialFailure: false)
                    switch json.data {
                        case .case1(let batch):
                            let output: [EncryptionBatchOutput] = batch.batchResults.map {  [weak failureResult] result in
                                switch result {
                                    case .case1(let encryption):
                                        return EncryptionBatchOutput(ciphertext: encryption.ciphertext, version: encryption.keyVersion, reference: encryption.reference)
                                    case .case2(let failure):
                                        failureResult?.hasPartialFailure = true
                                        failureResult?.error = failure.error
                                        return EncryptionBatchOutput(ciphertext: "", version: nil, reference: "")
                                }
                            }

                            if failureResult.hasPartialFailure, let message = failureResult.error {
                                let vaultError = VaultServerError.invalidRequest(errors: failureResult.error)
                                logger.debug(.init(stringLiteral: "Partial failure during batch encryption: \(message)"))
                                TracingSupport.handleResponse(error: vaultError, span, 400)
                            } else {
                                TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                                let eventName = "batch encryption with key \(key.type)"
                                span.addEvent(.init(name: eventName))
                                logger.trace(
                                    .init(stringLiteral: eventName),
                                    metadata: [
                                        TracingAttributes.vaultRequestID: .string(vaultRequestID)
                                    ])
                            }
                            return .init(
                                requestID: vaultRequestID,
                                hasPartialFailure: failureResult.hasPartialFailure,
                                output: output
                            )
                        case .case2:
                            throw VaultClientError.receivedUnexpectedResponse()
                    }
                case let .undocumented(statusCode, payload):
                    if statusCode == partialFailureResponseCode {
                        let errors: String?
                        if let body = payload.body {
                            let expectedLength: Int? = switch body.length {
                                case let .known(size): Int(size)
                                case .unknown: nil
                            }

                            let data = try await Data(collecting: body, upTo: expectedLength ?? 1024*1024)
                            do {
                                errors = try JSONDecoder().decode(VaultErrorBody.self, from: data).errors.joined(separator: ", ")
                            } catch {
                                errors = nil
                            }
                            if errors == nil {
                                let json = try JSONDecoder().decode(Operations.Encrypt.Output.Ok.Body.JsonPayload.self, from: data)

                                let failureResult = FailureResult(hasPartialFailure: false)
                                switch json.data {
                                    case .case1(let batch):
                                        let output: [EncryptionBatchOutput] = batch.batchResults.map {  [weak failureResult] result in
                                            switch result {
                                                case .case1(let encryption):
                                                    return EncryptionBatchOutput(ciphertext: encryption.ciphertext, version: encryption.keyVersion, reference: encryption.reference)
                                                case .case2(let failure):
                                                    let vaultError = VaultServerError.invalidRequest(errors: failure.error)
                                                    logger.debug(.init(stringLiteral: "Partial failure during batch encryption: \(failure.error)"))
                                                    TracingSupport.handleResponse(error: vaultError, span, statusCode)

                                                    failureResult?.hasPartialFailure = true
                                                    failureResult?.error = failure.error
                                                    return EncryptionBatchOutput(ciphertext: "", version: nil, reference: "")
                                            }
                                        }

                                        let vaultRequestID = json.requestId
                                        if failureResult.hasPartialFailure  {
                                            let message = failureResult.error
                                            let vaultError = VaultServerError.invalidRequest(errors: message)
                                            logger.debug(
                                                .init(stringLiteral: "Partial failure during batch encryption: \(message ?? "<nil>")"),
                                                metadata: [
                                                    TracingAttributes.vaultRequestID: .string(vaultRequestID)
                                                ]
                                            )
                                            TracingSupport.handleResponse(error: vaultError, span, statusCode)
                                        } else {
                                            throw VaultClientError.receivedUnexpectedResponse()
                                        }

                                        return .init(
                                            requestID: json.requestId,
                                            hasPartialFailure: true,
                                            output: output
                                        )
                                    case .case2:
                                        throw VaultClientError.receivedUnexpectedResponse()
                                }
                            }
                        } else {
                            errors = nil
                        }

                        let vaultError = VaultServerError.invalidRequest(errors: errors)
                        logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                        TracingSupport.handleResponse(error: vaultError, span, statusCode)
                        throw vaultError
                    } else {
                        let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                        logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                        TracingSupport.handleResponse(error: vaultError, span, statusCode)
                        throw vaultError
                    }
            }
        }
    }

    /// Rewraps the provided ciphertext using the latest version of the named key.
    ///
    /// Because this never returns plaintext, it is possible to delegate this functionality to untrusted users or scripts.
    ///
    /// - Parameters:
    ///   - ciphertext: ciphertext to decrypt.
    ///   - key: encryption key
    ///   - associatedData: base64 encoded associated data (also known as additional data or AAD) to also be authenticated with AEAD ciphers (`aes128-gcm96`, `aes256-gcm`, `chacha20-poly1305`, and `xchacha20-poly1305`). This is only needed if the encryption used it.
    ///   - context: base64 encoded context for key derivation. This is required if key derivation is enabled for this key
    ///   - nonce: base64 encoded nonce value. The value must be exactly 96 bits (12 bytes) long and the user must ensure that for any given context (and thus, any given encryption key) this nonce value is never reused.
    /// - Returns: wrapped ciphertext
    public func rewrap(
        ciphertext: String,
        key: EncryptionKey,
        associatedData: String? = nil,
        context: String? = nil,
        nonce: String? = nil
    ) async throws -> EncryptionResponse {
        return try await withSpan(Operations.RewrapCiphertext.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            if case .ed25519 = key.type {
                throw VaultClientError.invalidArgument("message encryption not supported for key type \(key.type)")
            }

            let response = try await engine.client.rewrapCiphertext(
                path: .init(transitPath: enginePath, secretKey: key.name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    ciphertext: ciphertext,
                    keyVersion: key.version,
                    nonce: nonce,
                    batchInput: nil,
                    context: context)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "ciphertext rewrapped with key \(key.type)"
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

    /// Generates a new high-entropy key and the value encrypted with the named key
    /// 
    /// - Parameters:
    ///   - outputType: type of key to generate. If `plaintext`, the plaintext key will be returned along with the ciphertext. If `wrapped`, only the ciphertext value will be returned
    ///   - keyName: name of the encryption key to use for generation
    ///   - associatedData: base64 encoded associated data (also known as additional data or AAD) to also be authenticated with AEAD ciphers (`aes128-gcm96`, `aes256-gcm`, `chacha20-poly1305`, and `xchacha20-poly1305`). This is only needed if the encryption used it.
    ///   - context: base64 encoded context for key derivation. This is required if key derivation is enabled for this key
    ///   - nonce: base64 encoded nonce value. The value must be exactly 96 bits (12 bytes) long and the user must ensure that for any given context (and thus, any given encryption key) this nonce value is never reused.
    ///   - bits: number of bits for key generation. It can be 128, 256, or 512.
    /// - Returns: new encryption key
    public func generateDataKey(
        outputType: EncryptionKey.Output,
        keyName: String,
        associatedData: String? = nil,
        context: String? = nil,
        nonce: String? = nil,
        bits: EncryptionKey.BitNumber? = nil
    ) async throws -> EncryptionResponse {
        return try await withSpan(Operations.GenerateKeyData.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.generateKeyData(
                path: .init(transitPath: enginePath, _type: outputType.rawValue, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    associatedData: associatedData,
                    context: context,
                    nonce: nonce,
                    bits: bits?.rawValue)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "new \(outputType.rawValue) key generated with key \(keyName)"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return .init(
                        requestID: vaultRequestID,
                        ciphertext: json.data.ciphertext,
                        plaintext: json.data.plaintext,
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

    /// Generates high-quality random bytes of the specified length.
    public func generateRandomBytes(
        _ randomBytes: GenerateRandomBytes
    ) async throws -> String {
        return try await withSpan(Operations.GenerateRandomBytes.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.generateRandomBytes(
                path: .init(transitPath: enginePath),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    bytes: randomBytes.count,
                    format: .init(rawValue: randomBytes.format.rawValue),
                    source: .init(rawValue: randomBytes.source.rawValue)
                    )
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "random bytes generated"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])

                    return json.data.randomBytes
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Hashes input with the specified algorithm
    /// - Parameters:
    ///   - input: base64 encoded input data
    ///   - algorithm: hash algorithm to use
    ///   - format: hex or base64 output format
    /// - Returns: formatted hash
    public func hash(
        input: String,
        algorithm: HashAlgorithm,
        format: GenerateRandomBytes.Format
    ) async throws -> String {
        return try await withSpan(Operations.HashData.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.hashData(
                path: .init(transitPath: enginePath),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    algorithm: .init(rawValue: algorithm.rawValue),
                    format: .init(rawValue: format.rawValue),
                    input: input)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "input hashed"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).hash_algorithm": .string(algorithm.rawValue),
                            "\(TracingAttributes.transitEngine).format": .string(format.rawValue)
                        ])

                    return json.data.sum
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Generates HMAC
    /// - Parameters:
    ///   - input: base64 encoded input data
    ///   - algorithm: hash algorithm to use
    ///   - keyName: name of the encryption key
    ///   - keyVersion: specific key version to use. `nil` uses the latest value
    /// - Returns: Returns the digest of given data using the specified hash algorithm and the named key.
    ///
    /// - warning: In FIPS 140-2 mode, the following hash algorithms are not certified and thus should not be used: sha3-224, sha3-256, sha3-384, and sha3-512.
    public func hmac(
        input: String,
        hashAlgorithm: HashAlgorithm,
        keyName: String,
        keyVersion: Int? = nil,
    ) async throws -> String {
        return try await withSpan(Operations.GenerateHmac.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.generateHmac(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    algorithm: .init(rawValue: hashAlgorithm.rawValue),
                    input: input,
                    keyVersion: keyVersion,
                    batchInput: nil)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "hmac generated"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).hash_algorithm": .string(hashAlgorithm.rawValue),
                            "\(TracingAttributes.transitEngine).key_name": .string(keyName),
                            "\(TracingAttributes.transitEngine).key_version": .stringConvertible(keyVersion ?? "latest")
                        ])

                    switch json.data {
                        case .case1:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case let .case2(result):
                            return result.hmac
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    /// Signs of the given data using the named key and the specified hash algorithm
    /// 
    /// 
    /// - Parameters:
    ///   - input: base64 encoded input data
    ///   - isInputPreHashed: Set to true when the input is already hashed. If the key type is rsa-2048, rsa-3072 or rsa-4096, then the algorithm used to hash the input should be indicated by the `hashAlgorithm` parameter. Just as the value to sign should be the base64-encoded representation of the exact binary data you want signed, when set, input is expected to be base64-encoded binary hashed data, not hex-formatted. (As an example, on the command line, you could generate a suitable input via `openssl dgst -sha256 -binary | base64`.)
    ///   - hashAlgorithm: hash algorithm to use for supporting key types (notably, not including ed25519 which specifies its own hash algorithm)
    ///   - keyName: name of encryption key
    ///   - keyVersion: version of the key to use. `nil` sets the latest version.
    ///   - context: Base64 encoded context for key derivation. Required if key derivation is enabled; currently only available with ed25519 keys.
    ///   - rsaSignatureAlgorithm: When using a RSA key, specifies the RSA signature algorithm to use for signing
    ///   - marshalingAlgorithm: The way in which the signature should be marshaled. This currently only applies to ECDSA keys
    /// - Returns: signature
    public func sign(
        input: String,
        isInputPreHashed: Bool = false,
        hashAlgorithm: HashAlgorithm?,
        keyName: String,
        keyVersion: Int? = nil,
        context: String? = nil,
        rsaSignatureAlgorithm: RSASignatureAlgorithm? = nil,
        marshalingAlgorithm: MarshalingAlgorithm? = nil
    ) async throws -> String {
        return try await withSpan(Operations.SignData.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let algorithm: Operations.SignData.Input.Body.JsonPayload.HashAlgorithmPayload?  = if let hashAlgorithm {
                .init(rawValue: hashAlgorithm.rawValue) ?? nil
            } else {
                Operations.SignData.Input.Body.JsonPayload.HashAlgorithmPayload.none
            }

            let saltLength: Operations.SignData.Input.Body.JsonPayload.SaltLengthPayload? = if case let .pss(lenght) = rsaSignatureAlgorithm {
                switch lenght {
                    case .auto: .case1(.auto)
                    case .hash: .case1(.hash)
                    case .count(let count): .case2(count)
                }
            } else {
                nil
            }


            let response = try await engine.client.signData(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(
                    .init(hashAlgorithm: algorithm,
                          input: input,
                          batchInput: nil,
                          context: context,
                          prehashed: isInputPreHashed,
                          signatureAlgorithm: rsaSignatureAlgorithm.flatMap({ .init(rawValue: $0.rawValue) }),
                          marshalingAlgorithm: marshalingAlgorithm.flatMap({ .init(rawValue: $0.rawValue) }),
                          saltLength: saltLength)
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "data signed"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).key_name": .string(keyName),
                            "\(TracingAttributes.transitEngine).key_version": .stringConvertible(keyVersion ?? "latest")
                        ])

                    switch json.data {
                        case .case1:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case let .case2(result):
                            return result.signature
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Verifies the signature or HMAC of a given input
    ///
    /// - Parameters:
    ///   - input: base64 encoded input data
    ///   - verificationKey: either a signature or hmac
    ///   - isInputPreHashed: Set to true when the input is already hashed. If the key type is rsa-2048, rsa-3072 or rsa-4096, then the algorithm used to hash the input should be indicated by the `hashAlgorithm` parameter. Just as the value to sign should be the base64-encoded representation of the exact binary data you want signed, when set, input is expected to be base64-encoded binary hashed data, not hex-formatted. (As an example, on the command line, you could generate a suitable input via `openssl dgst -sha256 -binary | base64`.)
    ///   - hashAlgorithm: hash algorithm to use for supporting key types (notably, not including ed25519 which specifies its own hash algorithm)
    ///   - keyName: name of encryption key
    ///   - keyVersion: version of the key to use. `nil` sets the latest version.
    ///   - context: Base64 encoded context for key derivation. Required if key derivation is enabled; currently only available with ed25519 keys.
    ///   - rsaSignatureAlgorithm: When using a RSA key, specifies the RSA signature algorithm to use for signing
    ///   - marshalingAlgorithm: The way in which the signature should be marshaled. This currently only applies to ECDSA keys
    /// - Returns: whether the signature or HMAC valid is
    public func verifySignedInput(
        _ input: String,
        verificationKey: VerificationType,
        isInputPreHashed: Bool = false,
        hashAlgorithm: HashAlgorithm?,
        keyName: String,
        keyVersion: Int? = nil,
        context: String? = nil,
        rsaSignatureAlgorithm: RSASignatureAlgorithm? = nil,
        marshalingAlgorithm: MarshalingAlgorithm? = nil
    ) async throws -> Bool {
        return try await withSpan(Operations.VerifySignedData.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let algorithm: Operations.VerifySignedData.Input.Body.JsonPayload.HashAlgorithmPayload?  = if let hashAlgorithm {
                .init(rawValue: hashAlgorithm.rawValue) ?? nil
            } else {
                Operations.VerifySignedData.Input.Body.JsonPayload.HashAlgorithmPayload.none
            }

            let saltLength: Operations.VerifySignedData.Input.Body.JsonPayload.SaltLengthPayload? = if case let .pss(lenght) = rsaSignatureAlgorithm {
                switch lenght {
                    case .auto: .case1(.auto)
                    case .hash: .case1(.hash)
                    case .count(let count): .case2(count)
                }
            } else {
                nil
            }

            let (hmac, signature): (String?, String?) = switch verificationKey {
            case .signature(let string):
                (nil, string)
            case .hmac(let string):
                (string, nil)
            }

            let response = try await engine.client.verifySignedData(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(
                    .init(
                        hashAlgorithm: algorithm,
                        input: input,
                        batchInput: nil,
                        context: context,
                        prehashed: isInputPreHashed,
                        signatureAlgorithm: rsaSignatureAlgorithm.flatMap({ .init(rawValue: $0.rawValue) }),
                        marshalingAlgorithm: marshalingAlgorithm.flatMap({ .init(rawValue: $0.rawValue) }),
                        saltLength: saltLength,
                        signature: signature,
                        hmac: hmac
                    )
                )
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "verifying signed input"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).key_name": .string(keyName),
                            "\(TracingAttributes.transitEngine).key_version": .stringConvertible(keyVersion ?? "latest")
                        ])

                    switch json.data {
                        case .case1:
                            throw VaultClientError.receivedUnexpectedResponse()
                        case let .case2(result):
                            return result.valid
                    }
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }

    
    /// Backup of a named key.
    ///
    /// The backup is in plaintext and contains all the configuration data and keys of all the versions along with the HMAC key. The response from this endpoint can be used with
    /// - Parameter keyName: name of the encryption key
    /// - Returns: plaintext backup with configuration data and versioned keys
    public func backup(
        keyName: String
    ) async throws -> String {
        return try await withSpan(Operations.BackupKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.backupKey(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken)
            )

            switch response {
                case .ok(let content):
                    let json = try content.body.json

                    let vaultRequestID = json.requestId
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)

                    logger.trace(
                        .init(stringLiteral: "backup key"),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).key_name": .string(keyName),
                        ])

                    return json.data.backup
                case let .undocumented(statusCode, payload):
                    let vaultError = await makeVaultError(statusCode: statusCode, payload: payload)
                    logger.debug(.init(stringLiteral: "operation failed with Vault Server error: \(vaultError)"))
                    TracingSupport.handleResponse(error: vaultError, span, statusCode)
                    throw vaultError
            }
        }
    }
    
    /// Restores a plaintext backup
    /// - Parameters:
    ///   - backup: plaintext backup
    ///   - name: name of the restored key
    ///   - force: If set, force the restore to proceed even if a key by this name already exists.
    public func restore(
        backup: String,
        name: String,
        force: Bool = false
    ) async throws {
        return try await withSpan(Operations.RestoreKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.restoreKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(
                    .init(
                        backup: backup,
                        force: force
                    )
                )
            )

            switch response {
                case .noContent:
                    let eventName = "encryption key restored"
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

    
    /// Removes older key versions setting a minimum version for the keyring. Once trimmed, previous versions of the key cannot be recovered.
    /// - Parameters:
    ///   - name: name of the encryption key
    ///   - minAvailableVersion: new minimum version
    /// - Returns: updated encryption key
    public func trimKey(
        name: String,
        minAvailableVersion: Int
    ) async throws -> EncryptionKeyResponse {
        return try await withSpan(Operations.TrimKey.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.trimKey(
                path: .init(transitPath: enginePath, secretKey: name),
                headers: .init(xVaultToken: sessionToken),
                body: .json(
                    .init(minAvailableVersion: minAvailableVersion)
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
                    let eventName = "encryption key soft-deleted"
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
    
    /// Signs a CSR using the given key name.
    ///
    /// - Note: The signing key must not be derived.
    /// - Parameters:
    ///   - csr: certificate signing request. If no CSR is provided, it signs an empty CSR. Otherwise, it signs the provided CSR, replacing its key material with the :name key material.
    ///   - keyName: name of the signing key.
    ///   - keyVersion: optional key version. `nil` uses the latest key version.
    /// - Returns: signed csr
    public func signCSR(
        _ csr: String?,
        keyName: String,
        keyVersion: Int? = nil
    ) async throws -> SignedCSRResponse {
        return try await withSpan(Operations.SignCsr.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.signCsr(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                    csr: csr,
                    version: keyVersion)
                )
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
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "csr signed"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID)
                        ])


                    return .init(
                        requestID: vaultRequestID,
                        csr: json.data.csr,
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
    
    /// Sets the certificate chain for the named key, ensuring the key material stays within the Transit engine and certificates are managed in one place.
    ///
    /// It also allows chain updates and rotation, as it will overwrite any existing certificate chain.
    /// - Parameters:
    ///   - certificateChain: certificate chain
    ///   - keyName: name of the encryption key
    ///   - keyVersion: optional key version. `nil` uses the latest key version.
    /// - Returns: the written certificate chain
    public func setCertificateChain(
        _ certificateChain: String,
        keyName: String,
        keyVersion: Int? = nil
    ) async throws -> CertificateChainResponse {
        return try await withSpan(Operations.SetCertificateChain.id, ofKind: .client) { span in
            let sessionToken = self.engine.token
            let enginePath = self.engine.mountPath

            let response = try await engine.client.setCertificateChain(
                path: .init(transitPath: enginePath, secretKey: keyName),
                headers: .init(xVaultToken: sessionToken),
                body: .json(.init(
                        certificateChain: certificateChain,
                        version: keyVersion)
                )
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
                    TracingSupport.handleVaultResponse(requestID: vaultRequestID, span, 200)
                    let eventName = "certificate chain was set"
                    span.addEvent(.init(name: eventName))
                    logger.trace(
                        .init(stringLiteral: eventName),
                        metadata: [
                            TracingAttributes.vaultRequestID: .string(vaultRequestID),
                            "\(TracingAttributes.transitEngine).key_name": .string(keyName),
                            "\(TracingAttributes.transitEngine).key_version": .stringConvertible(keyVersion ?? "latest")
                        ])


                    return .init(
                        requestID: vaultRequestID,
                        certificateChain: json.data.certificateChain,
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
    
    ///  Imports existing key material into a new transit-engine-managed encryption key.
    ///
    /// - Parameters:
    ///   - key: encryption key
    ///   - importedType: ciphertext or public key
    ///   - hashFunction: The hash function used for the RSA-OAEP step of creating the ciphertext.
    ///   - derivedContext: Specifies if key derivation is to be used. If enabled, all encrypt/decrypt requests to this named key must provide a context which is used for key derivation.
    ///   - isExportable:  Enables keys to be exportable.
    ///   - allowPlainTextBackup: If set, enables taking backup of named key in the plaintext format. Once set, this cannot be disabled.
    ///   - autoRotatePeriod: The period at which this key should be rotated automatically. Setting to `nil` will disable automatic key rotation.
    /// - Returns: the imported encryption key with its properties
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

private final class FailureResult {
    var hasPartialFailure: Bool
    var error: String?

    init(hasPartialFailure: Bool, error: String? = nil) {
        self.hasPartialFailure = hasPartialFailure
        self.error = error
    }
}

#endif
