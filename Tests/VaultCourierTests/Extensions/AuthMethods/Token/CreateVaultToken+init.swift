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

#if Pkl
import VaultCourier

extension CreateVaultToken {
    init(_ module: VaultToken.Module) {
        self.init(id: module.id,
                  roleName: module.role_name,
                  policies: module.policies,
                  meta: module.meta,
                  hasParent: module.no_parent ?? true,
                  hasDefaultPolicy: module.no_default_policy ?? true,
                  isRenewable: module.renewable,
                  ttl: module.ttl?.toSwiftDuration(),
                  type: .init(rawValue: module.type.rawValue),
                  tokenMaxTTL: module.explicit_max_ttl?.toSwiftDuration(),
                  displayName: module.display_name,
                  tokenNumberOfUses: module.num_uses,
                  tokenPeriod: module.period?.toSwiftDuration(),
                  entityAlias: module.entity_alias)
    }
}
#endif
