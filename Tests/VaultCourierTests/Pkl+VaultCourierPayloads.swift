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

import Testing

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import PklSwift

@testable import VaultCourier

extension IntegrationTests.Pkl {
    struct Payloads {
        @Test
        func create_database_static_role_with_pkl_file() async throws {
            let url = pklFixtureUrl(for: "Sample1/static_role.pkl")

            await #expect(throws: Never.self) {
                let config = try await PostgresStaticRole.loadFrom(source: .url(url))

                guard CreateDatabaseStaticRole(config) != nil else {
                    Issue.record("Failed to init CreateDatabaseStaticRole from pkl-generated payload")
                    return
                }
            }
        }

        @Test
        func create_approle_with_pkl_file() async throws {
            let url = pklFixtureUrl(for: "Sample1/app_role.pkl")

            await #expect(throws: Never.self) {
                _ = try await VaultAppRole.loadFrom(source: .url(url))
            }
        }

        @Test
        func create_token_with_pkl_file() async throws {
            let url = pklFixtureUrl(for: "Sample1/user_token.pkl")

            await #expect(throws: Never.self) {
                _ = try await VaultToken.loadFrom(source: .url(url))
            }
        }

        struct VaultDuration {
            @Test
            func vault_duration_style_for_seconds() async throws {
                let duration = Swift.Duration(secondsComponent: 5400, attosecondsComponent: 0)
                #expect(duration.formatted(.vaultSeconds) == "5400s")
            }

            @Test
            func vault_duration_style_for_hours() async throws {
                let duration = Swift.Duration(secondsComponent: 5400, attosecondsComponent: 0)
                #expect(duration.formatted(.vaultHours) == "1.5h")
            }
        }
    }
}
