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


public struct WrappedResponse: Sendable {
    public let requestId: String?

    /// Wrapped token
    public let token: String

    public let accessor: String

    public let timeToLive: Int

    public let createdAt: String

    public let creationPath: String

    public let wrappedAccessor: String
}

extension WrappedResponse {
    init(component: Components.Schemas.WrapAppRoleSecretIdResponse) {
        self.requestId = nil
        self.token = component.wrapInfo.token
        self.accessor = component.wrapInfo.accessor
        self.timeToLive = component.wrapInfo.ttl
        self.createdAt = component.wrapInfo.creationTime
        self.creationPath = component.wrapInfo.creationPath
        self.wrappedAccessor = component.wrapInfo.wrappedAccessor
    }
}
