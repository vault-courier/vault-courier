//
//  PklTestTrait.swift
//  vault-courier
//
//  Created by Javier Cuesta on 30.04.25.
//

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
