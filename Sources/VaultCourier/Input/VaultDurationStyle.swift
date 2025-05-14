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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Duration {
    /// Vault Duration Units. See [here](https://developer.hashicorp.com/vault/docs/concepts/duration-format)
    struct VaultDurationStyle: FormatStyle {

        var units: Unit

        /// The locale to use when formatting the duration.
        var locale: Locale = .init(identifier: "en_US_POSIX")

        func format(_ value: Duration) -> String {
            switch units {
                case .seconds:
                    return "\(value.components.seconds.formatted(.number.grouping(.never)))s"
                case .hours:
                    let duration = value
                    let unitsFormat = UnitsFormatStyle(allowedUnits: [.hours], width: .narrow, fractionalPart: .show(length: 1)).locale(locale)
                    return duration.formatted(unitsFormat)
            }
        }

        enum Unit: Codable {
            case seconds
            case hours
        }

        func locale(_ locale: Locale) -> Duration.VaultDurationStyle {
            .init(units: units, locale: locale)
        }
    }
}

extension FormatStyle where Self == Duration.VaultDurationStyle {
    static var vaultSeconds: Self { .init(units: .seconds) }
    static var vaultHours: Self { .init(units: .hours) }
}
