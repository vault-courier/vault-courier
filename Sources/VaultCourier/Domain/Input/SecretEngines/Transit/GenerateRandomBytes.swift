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

#if TransitEngineSupport

/// Request input to generate random bytes
public struct GenerateRandomBytes: Sendable {
    public enum Source: String, Sendable {
        case platfrom
        case all
    }

    public enum Format: String, Sendable {
        case hex
        case base64
    }

    /// Source of the requested bytes
    public let source: Self.Source

    /// Output format
    public let format: Self.Format

    /// Number of bytes
    public let count: Int

    public init(source: Self.Source,
                format: Self.Format,
                count: Int = 32) {
        self.source = source
        self.format = format
        self.count = count
    }
}

#endif
