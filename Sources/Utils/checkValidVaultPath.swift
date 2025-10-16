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

import RegexBuilder

extension String {
    /// Check if the string is a valid Vault mount path
    ///
    /// Mount paths cannot contain:
    /// - Spaces
    /// - Control characters (e.g. newline `\n`, tab `\t`)
    /// - URL-reserved characters that aren’t properly encoded, such as: `?, #, %, &, =, +, <, >, ;, "`
    /// - Backslashes (`\`). Only forward slashes (`/`) are valid separators
    /// - Double slashes (`//`). Vault normalizes paths, and these may cause conflicts
    /// - Leading slashes (e.g. `/secret/` instead of `secret/`)
    package var isValidVaultMountPath: Bool {
        let regex = Regex {
          /^/
          NegativeLookahead {
            ChoiceOf {
              "sys/"
              "auth/"
              "identity/"
              "cubbyhole/"
            }
          }
          NegativeLookahead {
            "/"
          }
          NegativeLookahead {
            Regex {
              ZeroOrMore {
                /./
              }
              "//"
            }
          }
          OneOrMore {
            CharacterClass(
              .anyOf("_-"),
              ("a"..."z"),
              ("0"..."9")
            )
          }
          ZeroOrMore {
            Regex {
              "/"
              OneOrMore {
                CharacterClass(
                  .anyOf("_-"),
                  ("a"..."z"),
                  ("0"..."9")
                )
              }
            }
          }
          Optionally {
            "/"
          }
          /$/
        }
        .anchorsMatchLineEndings()

        guard !isEmpty,
              self.contains(regex)
        else {
            return false
        }

        return true
    }
}
