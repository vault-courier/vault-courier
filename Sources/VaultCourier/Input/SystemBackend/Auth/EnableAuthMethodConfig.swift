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
    /// The path where this auth method should be enabled
    public let path: String

    /// The type of the backend. Example: \"userpass\"
    public let type: String

    /// User-friendly description for this credential backend.
    public let description: String?

    /// Configuration for this mount, such as `plugin_name`.
    public let config: [String: String]?

    /// The options to pass into the backend. See Auth method docs.
    public let options: [String: String]?

    /// Mark the mount as a local mount, which is not replicated and is unaffected by replication.
    public let local: Bool?

    /// Whether to turn on seal wrapping for the mount.
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
