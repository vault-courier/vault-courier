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
import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
import FoundationInternationalization
#else
import struct Foundation.Duration
#endif
import Utils

@Suite
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
