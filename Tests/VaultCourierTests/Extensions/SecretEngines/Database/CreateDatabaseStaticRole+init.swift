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
import VaultCourier

extension CreateDatabaseStaticRole {
    init?(_ module: PostgresStaticRole.Module) {
        let rotation: RotationStrategy
        if let rotationPeriod = module.rotation_period {
            rotation = .period(rotationPeriod.toSwiftDuration())
        } else if let rotationSchedule = module.rotation_schedule {
            rotation = .scheduled(.init(schedule: rotationSchedule,
                                        window: module.rotation_window?.toSwiftDuration()))
        } else {
            return nil
        }

        let credentialType: DatabaseCredentialMethod = if let credentialMethod = module.credential_type?.rawValue {
            .init(rawValue: credentialMethod) ?? .password
        } else {
            .password
        }

        self.init(vaultRoleName: module.vault_role_name,
                  databaseUsername: module.db_username,
                  databaseConnectionName: module.db_connection_name,
                  rotation: rotation,
                  rotationStatements: module.rotation_statements,
                  credentialType: credentialType,
                  credentialConfig: module.credential_config)
    }
}
#endif
