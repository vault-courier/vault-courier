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

extension CreateAppRole {
  init(_ module: VaultAppRole.Module) {
      self.init(
        name: module.role_name,
        bindSecretId: module.bind_secret_id,
        secretIdBoundCIDRS: module.secret_id_bound_cidrs,
        secretIdNumberOfUses: module.secret_id_num_uses,
        secretIdTTL: module.secret_id_ttl,
        localSecretIds: module.local_secret_ids,
        tokenPolicies: module.token_policies,
        tokenBoundCIDRS: module.token_bound_cidrs,
        tokenTTL: module.token_ttl,
        tokenMaxTTL: module.token_max_ttl,
        tokenNoDefaultPolicy: module.token_no_default_policy,
        tokenNumberOfUses: module.token_num_uses,
        tokenPeriod: module.token_period,
        tokenType: .init(rawValue: module.token_type.rawValue) ?? .default
      )
  }
}
