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

#if PklSupport
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import PklSwift

import VaultCourier

extension IntegrationTests.Pkl {
    @Suite(
        .disabled(), // Bug: This suite can only be called individually. Otherwise, it blocks when run with other suits. Seems to be due to Pkl
        .setupPkl(execPath: env("PKL_EXEC") ?? "/opt/homebrew/bin/pkl")
    )
    struct Payloads {
#if PostgresPluginSupport
        @Test
        func create_database_static_role_with_pkl_file() async throws {
            let url = pklFixtureUrl(for: "Sample1/static_role.pkl")

            await #expect(throws: Never.self) {
                let config = try await PostgresStaticRole.loadFrom(source: .url(url))

                guard PostgresStaticRoleConfig(config) != nil else {
                    Issue.record("Failed to init CreateDatabaseStaticRole from pkl-generated payload")
                    return
                }
            }
        }
#endif

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
    }
}
#endif
