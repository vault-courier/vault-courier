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

public enum TokenType: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
    /// Leases created by batch tokens are constrained to the remaining TTL of the batch tokens and, if the batch token is not an orphan, are tracked by the parent.
    /// They are revoked when the batch token's TTL expires, or when the batch token's parent is revoked (at which point the batch token is also denied access to Vault).
    ///
    /// As a corollary, batch tokens can be used across performance replication clusters, but only if they are orphan, since non-orphan tokens will not be able to ensure the validity of the parent token.
    case batch = "batch"

    /// Leases created by service tokens (including child tokens' leases) are tracked along with the service token and revoked when the token expires.
    case service = "service"

    case `default` = "default"

    case defaultService = "default-service"
    
    case defaultBatch = "default-batch"
}
