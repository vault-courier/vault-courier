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

#if MockSupport
import VaultCourier
import Testing
import Tracing
import InMemoryTracing
import Logging
import Utils
import HTTPTypes
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.Date
#endif

@testable import Instrumentation

@Suite(.serialized)
struct TracingTests {
    static let testTracer = {
        let tracer = InMemoryTracer()
        InstrumentationSystem.bootstrap(tracer)
        return tracer
    }()

    func withTracerSpan<Value: Sendable>(
        _ operation: () async throws -> Value
    ) async throws -> Value {
        let tracer = Self.testTracer
        return try await tracer.withSpan("TestSpan") { _ in
            return try await operation()
        }
    }

    // Spans are in reverse order. The last one is usually the login operation
    static var popSpans: [FinishedInMemorySpan] {
        Self.testTracer.popFinishedSpans()
    }

    static let clientToken = "b.AAAAAQJZ4d_EQOicFoz3O5of1b_Bg8kivgrxeQ_zzx62UzoqygeNxwopmuJChpFK9j"
    static let vaultRequestID = "bb10149f-39dd-8261-a427-d52e64922355"
    static let appRoleMountPath = "path/to/approle"
    static let metadata = ["tag1": "development"]
    static let displayName = "qa_token"

    static let transportClient = MockVaultClientTransport { req, _, _, _ in
        switch req.normalizedPath {
            case "/auth/token/lookup-self":
                return (.init(status: .ok),
                        try await MockVaultClientTransport.encode(response:
                            LookupTokenResponse(
                                requestID: vaultRequestID,
                                clientToken: clientToken,
                                accessor: "accessor_token",
                                createdAt: .now,
                                creationTimeToLive: .seconds(60),
                                displayName: "vault-client-token",
                                expiresAt: .now,
                                explicitMaxTimeToLive: .seconds(60*60),
                                timeToLive: .seconds(60),
                                policies: ["default"],
                                metadata: metadata,
                                isRenewable: true,
                                tokenType: .batch,
                                isOrphan: true,
                                numberOfUses: 0,
                                path: "auth/token/create")
                    )
                )

            case "/auth/\(appRoleMountPath)/login":

                return (.init(status: .ok),
                        try await MockVaultClientTransport.encode(response:
                            VaultAuthResponse(
                                requestID: vaultRequestID,
                                clientToken: clientToken,
                                accessor: "accessor_token",
                                tokenPolicies: ["default"],
                                metadata: ["tag1": "development"],
                                leaseDuration: .seconds(3600*24),
                                isRenewable: true,
                                entityID: "913160eb-837f-ee8c-e6aa-9ded162b5b75",
                                tokenType: .batch,
                                isOrphan: true,
                                numberOfUses: 0
                            )
                    )
                )

                case "/auth/token/create":
                return (.init(status: .ok),
                        try await MockVaultClientTransport.encode(response:
                            VaultAuthResponse(
                                requestID: vaultRequestID,
                                clientToken: clientToken,
                                accessor: "accessor_token",
                                tokenPolicies: ["default"],
                                metadata: metadata,
                                leaseDuration: .seconds(3600*24),
                                isRenewable: true,
                                entityID: "913160eb-837f-ee8c-e6aa-9ded162b5b75",
                                tokenType: .service,
                                isOrphan: true,
                                numberOfUses: 0
                            )
                    )
                )

            default:
                Issue.record("Unexpected request made to \(String(reflecting: req.path)): \(req)")
                throw TestError()
        }
    }

    @Test
    func trace_login_with_approle() async throws {
        try await withTracerSpan {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: Self.transportClient)
            try await vaultClient.login(method: .appRole(path: Self.appRoleMountPath,
                                                         credentials: .init(roleID: "role_id",
                                                                            secretID: "secret_id")))
        }
        
        let finishedSpans = Self.popSpans
        let span = try #require(finishedSpans.first(where: {$0.operationName == "auth-approle-login"}))
        #expect(span.errors.isEmpty)
        expectSpanAttributesEqual(
            span.attributes,
            [
                TracingSupport.AttributeKeys.responseStatusCode: 200,
                TracingSupport.AttributeKeys.vaultRequestID : .string(Self.vaultRequestID)
            ]
        )

        let expectedEvent = SpanEvent(name: "login",
                                      attributes: [TracingSupport.AttributeKeys.vaultAuthMethod: "approle"])
        let event = try #require(span.events.first)
        #expect(event.name == expectedEvent.name)
        #expect(event.attributes == expectedEvent.attributes)
    }

    @Test(.disabled("flaky test: due to data race with the previous test. TODO: Write a scoped trait to run these tests"))
    func trace_login_with_approle_error() async throws {
        try? await withTracerSpan {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: MockVaultClientTransport.forbidden)
            try await vaultClient.login(method: .appRole(path: Self.appRoleMountPath,
                                                         credentials: .init(roleID: "role_id",
                                                                            secretID: "secret_id")))
        }

        let finishedSpans = Self.popSpans
        let span = try #require(finishedSpans.first(where: {$0.operationName == "auth-approle-login"}))

        let error = try #require(span.errors.first?.error as? VaultServerError)
        let forbidden = VaultServerError.forbidden(errors: nil)
        #expect(error == forbidden)
        #expect(span.status == .init(code: .error))
    }

    @Test
    func trace_token_creation() async throws {
        try await withTracerSpan {
            let vaultClient = VaultClient(configuration: .defaultHttp(),
                                          clientTransport: Self.transportClient)
            try await vaultClient.login(method: .token(Self.clientToken))

            _ = try await vaultClient.createToken(
                .init(policies: ["default"],
                      meta: Self.metadata,
                      hasParent: false,
                      hasDefaultPolicy: true,
                      timeToLive: .seconds(60),
                      type: .service,
                      tokenMaxTTL: .seconds(60*60*4),
                      displayName: Self.displayName,
                      tokenNumberOfUses: nil)
            )
        }

        let finishedSpans = Self.popSpans
        let createdTokenSpans = finishedSpans.filter({$0.operationName == "token-create"})
        #expect(createdTokenSpans.count == 1)

        let span = try #require(createdTokenSpans.first)
        #expect(span.errors.isEmpty)

        expectSpanAttributesEqual(
            span.attributes,
            [
                "http.status_code": 200,
                "vault.request.id" : .string(Self.vaultRequestID)
            ]
        )

        let expectedEvent = SpanEvent(name: "token created", attributes: .init(Self.metadata.mapValues(SpanAttribute.string)))
        let event = try #require(span.events.first)
        #expect(event.name == expectedEvent.name)
        #expect(event.attributes == expectedEvent.attributes)
    }
}


#endif


