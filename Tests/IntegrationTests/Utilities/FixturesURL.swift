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

func fixtureUrl(for fixture: String) -> URL {
    fixturesDirectory().appending(path: fixture)
}

func fixturesDirectory(path: String = #filePath) -> URL {
    let url = URL(filePath: path)
    let testsDir = url.deletingLastPathComponent().deletingLastPathComponent()
    return testsDir.appending(path: "Fixtures", directoryHint: .isDirectory)
}

#if PklSupport
/// Returns URL of a pkl fixture file
/// - Parameter fixture: name of pkl file with extension, e.g. `test_static_role.pkl`
///
/// - Note: when used with `Module.loadFrom(source: .path(filePath))` pass the relative path
func pklFixtureUrl(for fixture: String) -> URL {
    let url = URL(filePath: "\(#filePath)/../../Fixtures/Pkl", directoryHint: .isDirectory)
    return url.appending(path: fixture)
}
#endif

