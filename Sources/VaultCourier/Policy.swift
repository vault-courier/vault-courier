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

extension VaultClient {
    public func createPolicy(name: String, hclPolicy: String) async throws {
        let sessionToken = try sessionToken()

        let response = try await client.policiesWriteAclPolicy(.init(
            path: .init(name: name),
            headers: .init(xVaultToken: sessionToken),
            body: .json(.init(policy: hclPolicy)))
        )

        switch response {
            case .noContent:
                logger.info("Policy written successfully!")
            case .undocumented(statusCode: let statusCode):
                logger.debug(.init(stringLiteral: "operation failed with \(statusCode)."))
        }
    }
}
