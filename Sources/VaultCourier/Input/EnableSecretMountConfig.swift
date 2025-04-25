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


public struct EnableSecretMountConfig: Sendable {
    public var mountType: String
    public var path: String
    public var description: String?
    public var config: [String: String]?
    public var options: [String: String]?
    public var local: Bool?
    public var sealWrap: Bool?
    public var externalEntropyAccess: Bool?
}

extension EnableSecretMountConfig {
    public init(_ module: MountConfiguration.Module) {
        self.mountType = module.type
        self.path = module.path
        let config: [String:String]? = if let config = module.config  {
            .init(uniqueKeysWithValues: zip(config.keys.map({ $0.rawValue}), config.values))
        } else {
            nil
        }
        self.config = config
        self.local = module.local
        self.options = module.options
        self.sealWrap = module.seal_wrap
        self.externalEntropyAccess = module.external_entropy_access
    }
}
