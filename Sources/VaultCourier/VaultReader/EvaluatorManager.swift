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

#if Pkl
import PklSwift

/// Perfoms `action`, returns its result and then closes the manager.
/// Executing on the global concurrent or task preferred executor
/// 
/// - Parameter action: The action to perform
/// - Parameter isolation: run under the given actor isolation. Defaults to surrounding actor
/// - Returns: The result of `action`
/// 
/// - Throws: Rethrows the closure error
public func withEvaluatorManager<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ action: (inout sending EvaluatorManager) async throws -> T
) async rethrows -> T {
    var manager: EvaluatorManager = .init()
    var closed = false
    do {
        let result = try await action(&manager)
        await manager.close()
        closed = true
        return result
    } catch {
        if !closed {
            await manager.close()
        }
        throw error
    }
}

#endif
