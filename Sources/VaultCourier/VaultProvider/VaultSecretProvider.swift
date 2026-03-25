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

#if ConfigProviderSupport
import Configuration
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONEncoder
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif
import Synchronization
import Tracing
import Utils

public enum DatabaseRole: Sendable {
    case `static`(role: String)
    case `dynamic`(role: String)
}

/// Vault Secrets Provider with registered actions
///
public final class VaultSecretProvider: Sendable {
    let client: VaultClient
    public let providerName: String = "VaultSecretProvider"

    /// In memory configuration values. This cache is updated when a fetch call succeeds.
    let cache: MutableInMemoryProvider

    /// An arbitrary closure on a VaultClient that returns the bytes of a secret.
    ///
    /// See ``keyValueSecret(mount:namespace:key:version:)`` and ``databaseCredentials(mount:namespace:role:)`` for predefined operations
    public typealias VaultClientOperation = @Sendable (VaultClient) async throws -> [UInt8]?

    let _evaluationMap: Mutex<[AbsoluteConfigKey: VaultClientOperation]>

    /// Creates a new vault secret provider with the specified configuration values.
    ///
    /// This initializer takes a dictionary of absolute configuration keys mapped to
    /// VaultClient closures that return bytes. Use this when you have already constructed `AbsoluteConfigKey`
    /// instances or when working with keys programmatically.
    ///
    /// ```swift
    /// let key1 = AbsoluteConfigKey(components: ["database", "host"], context: [:])
    /// let key2 = AbsoluteConfigKey(components: ["database", "port"], context: [:])
    ///
    /// let provider = VaultSecretProvider(
    ///     vaultClient: vaultClient,
    ///     evaluationMap: [
    ///         absoluteKey1: try await VaultSecretProvider.keyValueSecret(mount: "path/to/secret/mount", key: "secret_name"),
    ///         absoluteKey2: try await VaultSecretProvider.keyValueSecret(mount: "path/to/secret/mount", key: "secret_name", version: 2),
    ///         absoluteKey3: try await VaultSecretProvider.databaseCredentials(mount: path/to/database/mount", role: .static(name: "role_name"))
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - vaultClient: authenticated vault client
    ///   - evaluationMap: dictionary of absolute configuration keys mapped to VaultClient closures that return bytes
    ///   - initialValues: initial values in memory
    public init(
        vaultClient: VaultClient,
        evaluationMap: [AbsoluteConfigKey: VaultClientOperation] = [:],
        initialValues: [AbsoluteConfigKey: ConfigValue] = [:]
    ) {
        self.client = vaultClient
        self._evaluationMap = .init(evaluationMap)
        self.cache = .init(initialValues: initialValues)
    }
}

extension VaultSecretProvider {
    /// Get the associated VaultClient byte closure for the given key
    public func getEvaluation(for key: AbsoluteConfigKey) -> VaultSecretProvider.VaultClientOperation? {
        self._evaluationMap.withLock{ $0[key] }
    }

    /// Updates the ConfigKey/VaultClient closure mapping
    public func updateEvaluation(_ key: AbsoluteConfigKey, with action: @escaping VaultSecretProvider.VaultClientOperation) {
        self._evaluationMap.withLock {
            $0[key] = action
        }
    }
}

extension VaultSecretProvider: CustomStringConvertible {
    public var description: String {
        "VaultSecretProvider[\(client.apiURL.description)]"
    }
}

extension VaultSecretProvider: CustomDebugStringConvertible {
    public var debugDescription: String {
        let cacheDescription = cache.debugDescription.trimmingPrefix("MutableInMemoryProvider[").dropLast()
        return "VaultSecretProvider[\(client.apiURL.description), \(cacheDescription)]"
    }
}

extension VaultSecretProvider {    
    /// Operation to read a kv secret
    /// - Parameters:
    ///   - mount: mount path of the kv secret engine
    ///   - namespace: optional child namespace
    ///   - key: name of the secret key
    ///   - version: version of the secret
    /// - Returns: closure to read a kv secret from a Vault
    public static func keyValueSecret(
        mount: String,
        namespace: String? = nil,
        key: String,
        version: Int? = nil
    ) async throws -> VaultClientOperation {
        {
            client in
            let data = try await client.withKeyValueClient(namespace: namespace, mountPath: mount) { kvClient in
                try await kvClient.readKeyValueSecretData(key: key, version: version)
            }
            return Array(data)
        }
    }

    /// Operation to read a static secret which was response-wrapped
    /// - Parameters:
    ///   - as: Wrapping type
    ///   - token: wrapping-token
    ///   - namespace: optional child namespace
    /// - Returns: closure to read a wrapped secret from a Vault
    public static func unwrapSecret<WrappedType: Codable & Sendable>(
        as: WrappedType.Type,
        token: String,
        namespace: String? = nil,
    ) async throws -> VaultClientOperation {
        { client in
            try await client.withSystemBackend(namespace: namespace) { systemClient in
                let response: VaultResponse<WrappedType,Never> = try await systemClient.unwrapResponse(token: token)
                guard let unwrapped = response.data,
                      let data = try? JSONEncoder().encode(unwrapped) else {
                    return []
                }
                return Array(data)
            }
        }
    }
}

extension VaultSecretProvider: ConfigProvider {
    /// Reads secret value from memory cache if it was previously fetched from the Vault
    ///
    /// - Note: the secret value might be outdated. For retrieving latest secret see ``fetchValue(forKey:type:)``
    public func value(
        forKey key: AbsoluteConfigKey,
        type: Configuration.ConfigType
    ) throws -> LookupResult {
        return try self.cache.value(forKey: key, type: type)
    }

    /// Fetches secret value from remote Vault
    ///
    /// Example:
    ///
    /// ```swift
    /// try await provider.fetchValue(
    ///     forKey: .init(["database", "postgres", "credentials"])
    ///     type: .string
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - key: absolute key path
    ///   - type: secrets config type
    /// - Returns: secret lookup result
    public func fetchValue(
        forKey key: AbsoluteConfigKey,
        type: ConfigType
    ) async throws -> LookupResult {
        return try await withSpan("fetch-secret-value") { span in
            let encodedKey = key.description

            do {
                guard let execute = getEvaluation(for: key),
                      let buffer = try await execute(client) else {
                    return .init(encodedKey: encodedKey, value: nil)
                }

                let content: ConfigContent
                switch type {
                    case .string:
                        guard let json = String(data: Data(buffer), encoding: .utf8) else {
                            throw VaultClientError.receivedUnexpectedResponse()
                        }
                        content = .string(json)
                    case .int:
                        guard let intValue = try? JSONDecoder().decode(Int.self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .int(intValue)
                    case .double:
                        guard let doubleValue = try? JSONDecoder().decode(Double.self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .double(doubleValue)
                    case .bool:
                        guard let boolValue = try? JSONDecoder().decode(Bool.self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .bool(boolValue)
                    case .bytes:
                        content = .bytes(buffer)
                    case .stringArray:
                        guard let arrayValue = try? JSONDecoder().decode([String].self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .stringArray(arrayValue)
                    case .intArray:
                        guard let intArray = try? JSONDecoder().decode([Int].self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .intArray(intArray)
                    case .doubleArray:
                        guard let doubleArray = try? JSONDecoder().decode([Double].self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .doubleArray(doubleArray)
                    case .boolArray:
                        guard let boolArray = try? JSONDecoder().decode([Bool].self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .boolArray(boolArray)
                    case .byteChunkArray:
                        guard let byteChunkArray = try? JSONDecoder().decode([[UInt8]].self, from: Data(buffer)) else {
                            throw VaultSecretProviderError.configValueNotConvertible(name: key.description, type: type)
                        }
                        content = .byteChunkArray(byteChunkArray)
                }

                let value = ConfigValue(content, isSecret: true)
                self.cache.setValue(value, forKey: key)
                return .init(encodedKey: encodedKey, value: value)
            } catch let error as VaultServerError {
                TracingSupport.handleResponse(error: error, span)
                return .init(encodedKey: encodedKey, value: nil)
            } catch {
                TracingSupport.handleResponse(error: error, span)
                throw error
            }
        }
    }

    public func snapshot() -> any ConfigSnapshot {
        cache.snapshot()
    }

    public func watchSnapshot<Return: ~Copyable >(
        updatesHandler: nonisolated(nonsending) (ConfigUpdatesAsyncSequence<any ConfigSnapshot, Never>) async throws -> Return
    ) async throws -> Return {
        try await watchSnapshotFromSnapshot(updatesHandler: updatesHandler)
    }

    public func watchValue<Return: ~Copyable >(
        forKey key: AbsoluteConfigKey,
        type: ConfigType,
        updatesHandler: nonisolated(nonsending) (ConfigUpdatesAsyncSequence<Result<LookupResult, any Error>, Never>) async throws -> Return
    ) async throws -> Return {
        try await watchValueFromValue(forKey: key, type: type, updatesHandler: updatesHandler)
    }
}

#if DatabaseEngineSupport
extension VaultSecretProvider {
    static func fetchDatabaseCredential(
        client: DatabaseEngineClient,
        mount: String,
        role: DatabaseRole
    ) async throws -> Data {
        return try await withSpan("fetch-database-credential") { span in
            guard mount.isValidVaultMountPath else {
                let error = VaultSecretProviderError.invalidVault(mountPath: mount)
                TracingSupport.handleResponse(error: error, span)
                throw error
            }

            let credentials: DatabaseCredentials
            switch role {
                case .static(let name):
                    let response = try await client.databaseCredentials(staticRole: name)
                    credentials = DatabaseCredentials(username: response.username, password: response.password)

                case .dynamic(let name):
                    let response = try await client.databaseCredentials(dynamicRole: name)
                    credentials = DatabaseCredentials(username: response.username, password: response.password)
            }
            let data = try JSONEncoder().encode(credentials)
            return data
        }
    }

    /// Operation to read a database secret
    /// - Parameters:
    ///   - mount: mount path of database secret engine
    ///   - namespace: optional child namespace to add to the request
    ///   - role: static or dynamic database role
    /// - Returns: closure to read a database secret from Vault
    public static func databaseCredentials(
        mount: String,
        namespace: String? = nil,
        role: DatabaseRole
    ) async throws -> VaultClientOperation {
        { client in
            let data = try await client.withDatabaseClient(namespace: namespace, mountPath: mount) { databaseClient in
                try await self.fetchDatabaseCredential(client: databaseClient, mount: mount, role: role)
            }
            return Array(data)
        }
    }
}
#endif

// MARK: - Errors

/// An error thrown by ``VaultSecretProvider``.
///
/// These errors indicate issues with configuration value retrieval or conversion.
package enum VaultSecretProviderError: Error, CustomStringConvertible, Equatable {
    /// A configuration value could not be converted to the expected type.
    case configValueNotConvertible(name: String, type: ConfigType)

    case invalidVault(mountPath: String)

    package var description: String {
        switch self {
            case .configValueNotConvertible(let name, let type):
                "Config value for key '\(name)' failed to convert to type \(type)."
            case .invalidVault(mountPath: let mountPath):
                "'\(mountPath)' is not a valid Vault mount path."
        }
    }
}

#endif
