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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.Data
#endif

extension GenerateAppRoleToken {
    init(_ module: AppRoleToken.Module) {
        let roleName = module.role_name

        let data = try? JSONEncoder().encode(module.meta)
        let metadata = data?.base64EncodedString()

        let cidrList = module.cidr_list
        let tokenBoundCIDRS = module.token_bound_cidrs
        let tokenTTL = module.ttl
        let tokenNumberOfUses = module.num_uses
        let wrapTTL = module.wrap_ttl
        self.init(roleName: roleName,
                  metadata: metadata,
                  cidrList: cidrList,
                  tokenNumberOfUses: tokenNumberOfUses,
                  tokenBoundCIDRS: tokenBoundCIDRS,
                  tokenTimeToLive: tokenTTL?.toSwiftDuration(),
                  wrapTimeToLive: wrapTTL?.toSwiftDuration())
    }
}
#endif
