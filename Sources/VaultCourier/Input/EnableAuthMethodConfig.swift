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


public struct EnableAuthMethodConfig: Sendable {
    public let path: String
    public let type: String
    public let description: String?
    public let config: [String: String]?
    public let options: [String: String]?
    public let local: Bool?
    public let sealWrap: Bool?

    public init(path: String,
                type: String,
                description: String? = nil,
                config: [String : String]? = nil,
                options: [String : String]? = nil,
                local: Bool = false,
                sealWrap: Bool = false) {
        self.path = path
        self.type = type
        self.description = description
        self.config = config
        self.options = options
        self.local = local
        self.sealWrap = sealWrap
    }
}
