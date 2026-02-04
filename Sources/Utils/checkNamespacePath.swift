//===----------------------------------------------------------------------===//
//  Copyright (c) 2026 Javier Cuesta
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

import RegexBuilder

extension String {
    /// Check if the string is a valid namespace name
    ///
    /// Namespace names cannot contain:
    /// - CANNOT end with forward slash (`/`)
    /// - CANNOT contain spaces
    /// - CANNOT be one of the following reserved strings:
    ///     - `.`
    ///     - `..`
    ///     - `root`
    ///     - `sys`
    ///     - `audit`
    ///     - `auth`
    ///     - `cubbyhole`
    ///     - `identity`
    package var isValidNamespaceName: Bool {
        let reservedNames: Set<String> = [".", "..", "root", "sys", "audit", "auth", "cubbyhole", "identity"]
        if reservedNames.contains(self) {
            return false
        }

        if self.contains(" ") ||
           self.hasSuffix("/") ||
           self.isEmpty {
            return false
        }

        return true
    }

    package var isValidNamespace: Bool {
        guard !self.hasSuffix("/") else {
            return false
        }

        let hasInvalidName = self.split(separator: "/")
            .map(String.init)
            .first(where: { $0.isValidNamespaceName == false })
        guard hasInvalidName == nil
        else { return false }

        return true
    }
}
