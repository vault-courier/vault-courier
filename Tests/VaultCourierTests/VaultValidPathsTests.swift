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

struct VaultPaths {
    @Test(arguments: [
        "path.to.database",
        "/path/to/database",
        "path with spaces"
    ])
    func invalid_vault_mount_paths(_ mount: String) async throws {
        #expect(throws: VaultClientError.self) {
            guard mount.isValidVaultMountPath
            else { throw VaultClientError.invalidVault(mountPath: mount) }
        }
    }

    @Test(arguments: [
        "path/to/database/",
        "path_to_database"
    ])
    func valid_vault_mount_paths(_ mount: String) async throws {
        #expect(throws: Never.self) {
            guard mount.isValidVaultMountPath
            else { throw VaultClientError.invalidVault(mountPath: mount) }
        }
    }
}
