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


#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin.C
#else
#error("Unsupported platform")
#endif

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}

#if PklSupport
func setupPklEnv(execPath: String) {
    setenv("PKL_EXEC", execPath, 1)
}
#endif
