// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser

@main
struct VaultDynamicRole: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "sql_database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    mutating func run() async throws {
        print("Hello, world!")
    }
}