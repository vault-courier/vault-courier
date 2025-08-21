import VaultCourier
import OpenAPIAsyncHTTPClient
import PostgresNIO
import struct Vapor.Environment
import struct Foundation.URL

guard let roleID = Environment.get("ROLE_ID"),
      let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
else { fatalError("❌ Missing credentials for Vault authentication.") }

// 1. Read the secretID provided by the broker
let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)
let logger = Logger(label: "migrator")