//
// This source file is part of the Hummingbird server framework project
// Copyright (c) the Hummingbird authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Tracing
import Testing

func expectSpanAttributesEqual(
    _ lhs: @autoclosure () -> SpanAttributes,
    _ rhs: @autoclosure () -> [String: SpanAttribute],
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column
) {
    var rhs = rhs()

    // swift-format-ignore: ReplaceForEachWithForLoop
    lhs().forEach { key, attribute in
        if let rhsValue = rhs.removeValue(forKey: key) {
            #expect(rhsValue == attribute, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        } else {
            Issue.record(
                #"Did not specify expected value for "\#(key)", actual value is "\#(attribute)"."#,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column)
            )
        }
    }

    if !rhs.isEmpty {
        Issue.record(
            #"Expected attributes "\#(rhs.keys)" are not present in actual attributes."#,
            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column)
        )
    }
}
