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

import VaultCourier

extension CreateDatabaseStaticRole {
    init(_ module: PostgresStaticRole.Module) {
        self.init(vaultRoleName: module.vault_role_name,
                  databaseUsername: module.db_username,
                  databaseConnectionName: module.db_connection_name,
                  rotationPeriod: module.rotation_period,
                  rotationSchedule: module.rotation_schedule,
                  rotationWindow: module.rotation_window,
                  rotationStatements: module.rotation_statements,
                  credentialType: module.credential_type?.rawValue,
                  credentialConfig: module.credential_config)
    }
}
