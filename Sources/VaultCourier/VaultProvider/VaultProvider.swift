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
import struct Foundation.Data
#endif

/// Vault Secrets Provider
public struct VaultProvider: Sendable {
    let client: VaultClient
    public let providerName: String = "VaultProvider"

    /// In memory configuration values. This cache is updated when a fetch call succeeds.
    let cache: MutableInMemoryProvider

    static let keyEncoder: SeparatorKeyEncoder = .dotSeparated

    public init(
        vaultClient: VaultClient,
        initialValues: [AbsoluteConfigKey: ConfigValue] = [:],
    ) {
        self.client = vaultClient
        self.cache = .init(initialValues: initialValues)
    }
}

extension VaultProvider: CustomStringConvertible {
    public var description: String {
        "VaultProvider[\(client.apiURL.description)]"
    }
}

extension VaultProvider: CustomDebugStringConvertible {
    public var debugDescription: String {
        let cacheDescription = cache.debugDescription.trimmingPrefix("MutableInMemoryProvider[").dropLast()
        return "VaultProvider[\(client.apiURL.description), \(cacheDescription)]"
    }
}


extension VaultProvider {
    /// Secret engines are Vault components for storing and generating secrets.
    public enum SecretEngine: String {
        case keyValue

        #if DatabaseEngineSupport
        case database
        #endif
    }

    /// Create a context for reading Vault secrets
    /// - Parameters:
    ///   - secretEngine: secret engine type
    ///   - mount: mount path to secret engine
    ///   - url: URL pointing to secret
    /// - Returns: Configuration Context for triggering the VaultProvider
    public static func makeContext(
        _ secretEngine: SecretEngine,
        mount: String,
        url: URL
    ) -> [String: ConfigContextValue] {
        [
            Self.engineContextKey: .string(secretEngine.rawValue),
            Self.mountContextKey: .string(mount),
            Self.urlContextKey: .string(url.absoluteString)
        ]
    }

    public static func makeContext(
        _ secretEngine: SecretEngine,
        mount: String,
        url: String
    ) throws -> [String: ConfigContextValue] {
        guard let url = URL(string: url) else {
            throw VaultProviderError.invalidContextURL(url, name: "")
        }
        return Self.makeContext(secretEngine, mount: mount, url: url)
    }

    package static let engineContextKey = "engine"
    package static let mountContextKey = "mount"
    package static let urlContextKey = "url"
}

extension VaultProvider: ConfigProvider, ConfigSnapshotProtocol {
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
    /// It is necessary to pass a context key with secret engine type, mount path and secret url.
    ///
    /// Example:
    /// 
    /// ```swift
    /// try await sut.fetchValue(
    ///     forKey: .init(
    ///         ["database", "postgres", "credentials"],
    ///         context: [
    ///             "engine": .string("database"),
    ///             "mount": .string("path/to/database/mount"),
    ///             "url": .string("/path/to/database/mount/creds/role_name")
    ///         ]),
    ///     type: .string
    /// )
    /// ```
    ///
    /// Use ``VaultProvider/makeContext(_:mount:url:)-(_,_,URL)`` helper functions to create the vault secret context
    ///
    /// - Note: secrets config type can only be `.string` or `.bytes`
    /// 
    /// - Parameters:
    ///   - key: absolute key path _with_ context
    ///   - type: secrets config type which can only be `.string` or `.bytes`
    /// - Returns: secret lookup result or `nil` if the key context is not a valid vault context or the
    public func fetchValue(
        forKey key: AbsoluteConfigKey,
        type: ConfigType
    ) async throws -> LookupResult {
        let encodedKey = Self.keyEncoder.encode(key)
        
        guard let secretsEngine = key.context[Self.engineContextKey],
              let mount = key.context[Self.mountContextKey],
              case let .string(urlString) = key.context[Self.urlContextKey]
        else {
            return .init(encodedKey: encodedKey, value: nil)
        }

        let relativeURL = urlString.hasPrefix(self.client.apiURL.absoluteString) ? String(urlString.dropFirst(self.client.apiURL.absoluteString.count)) : urlString
        guard let url = URL(string: relativeURL)
        else {
            throw VaultProviderError.malformed(url: urlString)
        }

        // Check supported secret engines
        guard let engineContext = SecretEngine(rawValue: secretsEngine.description) else {
            throw VaultProviderError.unsupported(engine: secretsEngine.description)
        }

        let content: ConfigContent
        switch engineContext {
            case .keyValue:
                let components: (secretKey: String, version: Int?)
                if let (_, secretKey, version) = try KeyValueReaderParser(mount: mount.description).parse(url),
                   !secretKey.hasPrefix("data/") {
                    components = (secretKey, version)
                } else if let (_, secretKey, version) = try KeyValueDataPathParser().parse(url){
                    components = (secretKey, version)
                } else {
                    throw VaultProviderError.invalidContextURL(url.absoluteString, name: encodedKey)
                }

                let buffer = try await client.readKeyValueSecretData(
                    enginePath: mount.description,
                    key: components.secretKey,
                    version: components.version
                )

                switch type {
                    case .string:
                        guard let json = String(data: buffer, encoding: .utf8) else {
                            throw VaultClientError.receivedUnexpectedResponse()
                        }
                        content = .string(json)
                    case .bytes:
                        content = .bytes(Array(buffer))
                    case .int, .double, .bool, .boolArray, .stringArray, .doubleArray, .intArray, .byteChunkArray:
                        throw VaultProviderError.configValueNotConvertible(name: key.description, type: type)
                }

            #if DatabaseEngineSupport
            case .database:
                let parser = DatabaseReaderParser(mount: mount.description)
                if let (enginePath, role) = try parser.parse(url) {
                    let buffer = try await readDatabaseCredential(mount: enginePath, role: role)

                    switch type {
                        case .string:
                            guard let json = String(data: Data(buffer), encoding: .utf8) else {
                                throw VaultClientError.receivedUnexpectedResponse()
                            }
                            content = .string(json)
                        case .bytes:
                            content = .bytes(Array(buffer))
                        case .int, .double, .bool, .boolArray, .stringArray, .doubleArray, .intArray, .byteChunkArray:
                            throw VaultProviderError.configValueNotConvertible(name: key.description, type: type)
                    }
                } else {
                    throw VaultProviderError.invalidContextURL(url.absoluteString, name: encodedKey)
                }
                #endif
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
extension VaultProvider {
    func readDatabaseCredential(mount: String, role: DatabaseRole) async throws -> [UInt8] {
        let credentials: DatabaseCredentials
        switch role {
            case .static(let name):
                let response = try await client.databaseCredentials(staticRole: name, enginePath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)

            case .dynamic(let name):
                let response = try await client.databaseCredentials(dynamicRole: name, enginePath: mount)
                credentials = DatabaseCredentials(username: response.username, password: response.password)
        }
        let data = try JSONEncoder().encode(credentials)
        return Array(data)
    }
}
#endif

// MARK: - Errors

/// An error thrown by VaultProvider.
///
/// These errors indicate issues with configuration value retrieval or conversion.
package enum VaultProviderError: Error, CustomStringConvertible, Equatable {
    case unsupported(engine: String)

    case malformed(url: String)

    /// The context URL is not valid and not recognized by the parsers
    case invalidContextURL(_ url: String, name: String)

    /// A configuration value could not be converted to the expected type.
    case configValueNotConvertible(name: String, type: ConfigType)

    package var description: String {
        switch self {
            case .invalidContextURL(let url, name: let name):
                "Invalid context url '\(url)' in configuration '\(name)'"
            case .configValueNotConvertible(let name, let type):
                "Config value for key '\(name)' failed to convert to type \(type)."
            case .malformed(url: let url):
                "Malformed url '\(url)'"
            case .unsupported(engine: let engine):
                "Unsupported secret engine '\(engine)'"
        }
    }
}

#endif
