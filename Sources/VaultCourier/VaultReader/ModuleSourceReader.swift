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

extension VaultClient {
    /// The file path to the pkl ModuleSource
    public func readConfiguration(
        filepath: String
    ) async throws -> String {
        do {
            let output = try await withEvaluatorManager(isolation: self) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateOutputText(source: .path(filepath))
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    public func readConfiguration(
        text: String
    ) async throws -> String {
        do {
            let output = try await withEvaluatorManager(isolation: self) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateOutputText(source: .text(text))
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    public func readConfiguration<T>(
        source: ModuleSource,
        as type: T.Type,
    ) async throws -> T
    where T: Decodable & Sendable {
        do {
            // `withEvaluatorManager` is executing on VaultClient
            // Closure inherits VaultClient isolation
            // We explicitly set withEvaluatorManager to be isolated to the VaultClient
            let output = try await withEvaluatorManager(isolation: self) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                // Executing on VaultClient actor
                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateModule(source: source, as: type)
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }

    public func readConfiguration<T>(
        source: ModuleSource,
        expression: String,
        as type: T.Type,
    ) async throws -> T
    where T: Decodable & Sendable {
        do {
            let output = try await withEvaluatorManager(isolation: self) { manager in
                let readerOptions = EvaluatorOptions.preconfigured
                    .withResourceReader(self)

                return try await manager.withEvaluator(options: readerOptions) { evaluator in
                    return try await evaluator.evaluateExpression(source: source, expression: expression, as: type)
                }
            }

            return output
        } catch let error as PklSwift.PklError {
            logger.debug(.init(stringLiteral: String(describing: error.message)))
            throw VaultClientError.readingConfigurationFailed()
        }
    }
}

#endif
