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

#if PklSupport
import Testing

struct PklSupportTrait: SuiteTrait, TestTrait, TestScoping {
    let path: String

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        let executablePath = path
        setupPklEnv(execPath: executablePath)
        try await function()
    }
}

extension SuiteTrait where Self == PklSupportTrait {
    static func setupPkl(execPath: String) -> Self {
        return Self(path: execPath)
    }
}

extension TestTrait where Self == PklSupportTrait {
    static func setupPkl(execPath: String) -> Self {
        return Self(path: execPath)
    }
}
#endif
