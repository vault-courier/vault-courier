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

extension EnableSecretMountConfig {
    init(_ module: MountConfiguration.Module) {
        let mountType = module.type
        let path = module.path
        let config: [String:String]? = if let config = module.config  {
            .init(uniqueKeysWithValues: zip(config.keys.map({ $0.rawValue}), config.values))
        } else {
            nil
        }
        let local = module.local
        let options = module.options
        let sealWrap = module.seal_wrap
        let externalEntropyAccess = module.external_entropy_access
        self.init(
            mountType: mountType.rawValue,
            path: path,
            description: module.description,
            config: config,
            options: options,
            local: local,
            sealWrap: sealWrap,
            externalEntropyAccess: externalEntropyAccess
        )
    }
}
#endif
