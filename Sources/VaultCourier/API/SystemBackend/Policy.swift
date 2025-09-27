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
import struct Foundation.URL
#endif

extension VaultClient {
    
    /// Add a new or update an existing ACL policy.
    ///
    /// - Parameters:
    ///   - hcl: ACL policy in HCL format
    public func createPolicy(
        hcl: ACLPolicyHCL
    ) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.createPolicy(hcl)
        }
    }

    /// Add a new or update an existing ACL policy.
    ///
    /// - Parameters:
    ///   - name: name of the policy
    ///   - contentOf: URL to a ACL policy in HCL format
    public func createPolicy(
        name: String,
        contentOf: URL
    ) async throws {
        let policy = try String(contentsOf: contentOf, encoding: .utf8)
        try await createPolicy(hcl: .init(name: name, policy: policy))
    }
    
    /// Retrieves an ACL policy
    /// - Parameter name: name of the policy
    /// - Returns: Named ACL policy in HCL format
    public func readPolicy(name: String) async throws -> ACLPolicyHCL {
        try await withSystemBackend { systemBackend in
            try await systemBackend.readPolicy(name: name)
        }
    }

    /// Deletes an ACL policy
    /// - Parameter name: name of ACL policy
    public func deletePolicy(name: String) async throws {
        try await withSystemBackend { systemBackend in
            try await systemBackend.deletePolicy(name: name)
        }
    }
}
