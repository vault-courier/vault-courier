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

#if PklSupport && MockSupport
import Testing

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif
import PklSwift

import VaultCourier

extension IntegrationTests.Pkl {
    @Suite(
        .bug(
            "https://github.com/swiftlang/swift-package-manager/issues/8394",
            "swift test is hanging on GitHub Actions, started in Swift 6.0+"
        ),
        .serialized,
        .setupPkl(execPath: env("PKL_EXEC") ?? IntegrationTests.localPklExecPath)
    )
    struct ModuleSourceReader {
        @Test
        func custom_parse_strategy() async throws {
            struct AppConfig: Codable, Sendable {
                var secrets: String
            }

            let fooValue = "bar"
            let zipValue = "zap"

            let customPath = "/sys/wrapping/unwrap"
            let mockClient = MockVaultClientTransport { req, _, _, _ in
                switch req.normalizedPath {
                    case customPath:
                        return (.init(status: .ok), .init("""
                            {
                              "request_id": "d4eb86fe-1a60-7cef-5a97-623bb789891c",
                              "lease_id": "",
                              "renewable": false,
                              "lease_duration": 0,
                              "data": {
                                "foo": "\(fooValue)",
                                "zip": "\(zipValue)"
                              },
                              "wrap_info": null,
                              "warnings": null,
                              "auth": null
                            }
                            """))
                    default:
                        Issue.record("Unexpected request made to \(String(reflecting: req.path))")
                        throw TestError()
                }
            }

            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: mockClient)
            try await vaultClient.login(method: .token("test_token"))

            let scheme = "vault.wrap"
            let sut = try vaultClient.makeResourceReader(scheme: scheme) { client, url in
                try await VaultClient.CustomReader(client: client, customPath: customPath).parse(url) ?? []
            }

            // MUT
            let output = try await withEvaluator(options: .preconfigured.withResourceReader(sut)) { evaluator in
                try await evaluator.evaluateModule(
                    source: .text("""
                    secrets: String = read("\(scheme):\(customPath)?token=wrapping_token").text
                    """),
                    as: AppConfig.self
                )
            }

            let secrets = try JSONDecoder().decode(WrappingTestSecret.self, from: Data(output.secrets.utf8))
            #expect(secrets.foo == fooValue)
            #expect(secrets.zip == zipValue)
        }
    }
}

fileprivate struct WrappingTestSecret: Codable {
    let foo: String
    let zip: String
}

fileprivate extension VaultClient {
    struct CustomReader {
        let client: VaultClient
        let customPath: String

        func parse(_ url: URL) async throws -> [UInt8]? {
            let relativePath = url.relativePath.removeSlash()

            if !customPath.isEmpty,
               relativePath.starts(with: customPath.removeSlash()) {
                let query = url.query()
                let token: String? = if let query {
                    String(query.dropFirst("token=".count))
                } else {
                    nil
                }
                let response: VaultResponse<WrappingTestSecret, Never> = try await client.withSystemBackend { systemBackend in
                    try await systemBackend.unwrapResponse(token: token)
                }

                let data = try response.data.map(JSONEncoder().encode) ?? Data()
                return Array(data)
            } else {
                return nil
            }
        }
    }
}

#endif
