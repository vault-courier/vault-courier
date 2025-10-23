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

import HTTPTypes

extension HTTPRequest {
    package var normalizedPath: String? {
        guard let path = self.path else {
            return nil
        }
        var result = ""
        var i = path.startIndex

        while i < path.endIndex {
            // Check if we have at least 3 characters remaining for "%2F"
            let remaining = path.distance(from: i, to: path.endIndex)

            if remaining >= 3 {
                let nextThree = path[i..<path.index(i, offsetBy: 3)]

                if nextThree == "%2F" {
                    result.append("/")
                    i = path.index(i, offsetBy: 3)
                    continue
                }
            }

            result.append(path[i])
            i = path.index(after: i)
        }

        return result
    }
}
