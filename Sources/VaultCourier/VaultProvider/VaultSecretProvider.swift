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

    public typealias ApiOperation = @Sendable (VaultClient) async throws -> [UInt8]

    let _evaluationMap: Mutex<[AbsoluteConfigKey: ApiOperation]>

    public static let keyEncoder: SeparatorKeyEncoder = .dotSeparated

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
        evaluationMap: [AbsoluteConfigKey: ApiOperation] = [:],
        initialValues: [AbsoluteConfigKey: ConfigValue] = [:]
    ) {
        self.client = vaultClient
        self._evaluationMap = .init(evaluationMap)
        self.cache = .init(initialValues: initialValues)
    }
}

extension VaultSecretProvider {
    public func getEvaluation(for key: AbsoluteConfigKey) -> (@Sendable (VaultClient) async throws -> [UInt8])? {
        self._evaluationMap.withLock{ $0[key] }
    }

    public func updateEvaluation(_ key: AbsoluteConfigKey, with action: @escaping @Sendable (VaultClient) async throws -> [UInt8]) {
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
    /// Secret engines are Vault components for storing and generating secrets.
    public enum SecretEngine: String {
        case keyValue

        #if DatabaseEngineSupport
        case database
        #endif
    }

    package static let versionContextKey = "version"

    public static func keyValueSecret(mount: String, key: String, version: Int? = nil) async throws -> ApiOperation {
        { Array(try await $0.readKeyValueSecretData(mountPath: mount, key: key, version: version)) }
    }
}

extension VaultSecretProvider: ConfigProvider, ConfigSnapshotProtocol {
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
    /// try await sut.fetchValue(
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
        let encodedKey = Self.keyEncoder.encode(key)

        guard let execute = getEvaluation(for: key) else {
            return .init(encodedKey: encodedKey, value: nil)
        }

        let buffer = try await execute(client)

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
        self.cache.setValue(value, forKey: encodedKey, context: key.context)
        return .init(encodedKey: encodedKey, value: value)
    }

    public func watchValue<Return>(
        forKey key: AbsoluteConfigKey,
        type: ConfigType,
        updatesHandler: (ConfigUpdatesAsyncSequence<Result<LookupResult, any Error>, Never>) async throws -> Return
    ) async throws -> Return {
        try await watchValueFromValue(forKey: key, type: type, updatesHandler: updatesHandler)
    }

    public func snapshot() -> any ConfigSnapshotProtocol {
        self
    }

    public func watchSnapshot<Return>(
        updatesHandler: (ConfigUpdatesAsyncSequence<any ConfigSnapshotProtocol, Never>) async throws -> Return
    ) async throws -> Return {
        try await watchSnapshotFromSnapshot(updatesHandler: updatesHandler)
    }
}

#if DatabaseEngineSupport
extension VaultSecretProvider {
    static func fetchDatabaseCredential(
        client: VaultClient,
        mount: String,
        role: DatabaseRole
    ) async throws -> Data {
        guard mount.isValidVaultMountPath else {
            throw VaultSecretProviderError.invalidVault(mountPath: mount)
        }

        let credentials: DatabaseCredentials
        switch role {
            case .static(let name):
                let response = try await client.databaseCredentials(staticRole: name, mountPath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)

            case .dynamic(let name):
                let response = try await client.databaseCredentials(dynamicRole: name, mountPath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)
        }
        let data = try JSONEncoder().encode(credentials)
        return data
    }

    public static func databaseCredentials(mount: String, role: DatabaseRole) async throws -> ApiOperation {
        { Array(try await self.fetchDatabaseCredential(client: $0, mount: mount, role: role)) }
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
