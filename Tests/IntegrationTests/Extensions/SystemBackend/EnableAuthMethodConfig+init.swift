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

extension EnableAuthMethodConfig {
    init(_ module: AuthMethodConfig.Module) {
        let config: [String:String]? = if let config = module.config  {
            .init(uniqueKeysWithValues: zip(config.keys.map({ $0.rawValue}), config.values))
        } else {
            nil
        }
        self.init(path: module.path,
                  type: module.type.rawValue,
                  description: module.description,
                  config: config,
                  options: module.options,
                  isLocal: module.local ?? false,
                  sealWrap: module.seal_wrap ?? false)
    }
}
#endif
