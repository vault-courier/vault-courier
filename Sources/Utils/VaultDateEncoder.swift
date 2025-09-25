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

import OpenAPIRuntime
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Date
#endif

/// A transcoder for dates encoded as an ISO-8601 string (in RFC 3339 format) which first
/// tries to decode with fractional seconds precision and then fallbacks to ISO8601 without fractional precision
///
/// - Note: This will be deprecated after Swift 6.3 as it will be the default behavior in
/// `Foundation.Date.ISO8601FormatStyle` (see comment in the property `includingFractionalSeconds` of this type)
package struct VaultDateTranscoder: DateTranscoder, Sendable {
    /// Creates and returns an ISO 8601 formatted string representation of the specified date.
    package func encode(_ date: Date) throws -> String {
        var dateAsString = date.ISO8601Format(iso8601WithFractionalSecondsStyle)
        if dateAsString.isEmpty {
            dateAsString = date.ISO8601Format(iso8601Style)
        }
        return dateAsString
    }
    
    package func decode(_ dateString: String) throws -> Date {
        do {
            return try iso8601WithFractionalSecondsStyle.parse(dateString)
        } catch {
            return try iso8601Style.parse(dateString)
        }
    }

    /// The underlying date format style.
    private let iso8601Style: Date.ISO8601FormatStyle

    private let iso8601WithFractionalSecondsStyle: Date.ISO8601FormatStyle

    package init() {
        iso8601Style = Date.ISO8601FormatStyle()
        let style = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        iso8601WithFractionalSecondsStyle = style
    }
}

extension DateTranscoder where Self == VaultDateTranscoder {
    /// A transcoder that transcodes dates as ISO-8601–formatted string (in RFC 3339 format) with fractional seconds and fallbacks to ISO-8601 without fractional seconds if it fails
    package static var fallbackISO8601: Self { VaultDateTranscoder() }
}
