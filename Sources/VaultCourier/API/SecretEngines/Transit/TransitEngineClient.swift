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
        type: EncryptionKey,
        isDerived: DerivedEncryption? = nil,
        isExportable: Bool = false,
        allowPlainTextBackup: Bool = false,
        autoRotatePeriod: Duration? = nil
    ) async throws -> EncryptionKeyResponse? {

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
                guard let encryptionKeyType = EncryptionKey(rawValue: json.data._type.rawValue) else {
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

                let keys: [AsymmetricKeyData] = json.data.keys.additionalProperties.values.map({ value in
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

                    return EncryptionKeyResponse.init(
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
}
#endif
