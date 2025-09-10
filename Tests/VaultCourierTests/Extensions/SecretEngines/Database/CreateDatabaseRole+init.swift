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

extension CreateDatabaseRole {
    init(_ module: PostgresRole.Module) {
        let credentialType: DatabaseCredentialMethod = if let credentialMethod = module.credential_type?.rawValue {
            .init(rawValue: credentialMethod) ?? .password
        } else {
            .password
        }

        self.init(vaultRoleName: module.name,
                  databaseConnectionName: module.db_connection_name,
                  defaultTTL: module.default_ttl?.toSwiftDuration(),
                  maxTTL: module.max_ttl?.toSwiftDuration(),
                  creationStatements: module.creation_statements,
                  revocationStatements: module.revocation_statements,
                  rollbackStatements: module.rollback_statements,
                  renewStatements: module.renew_statements,
                  rotation_statements: module.rotation_statements,
                  credentialType: credentialType,
                  credentialConfig: module.credential_config)
    }
}
#endif
