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

#if ConfigProviderSupport

import Configuration
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

extension DatabaseCredentials: ExpressibleByConfigString {
    public init?(configString: String) {
        guard let data = configString.data(using: .utf8),
              let credentials = try? JSONDecoder().decode(DatabaseCredentials.self, from: data) else {
            return nil
        }
        self = credentials
    }
    
    public var description: String {
        "username=\(username), password=<REDACTED>"
    }
}

#endif
