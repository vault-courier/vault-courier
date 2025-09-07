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

import OpenAPIRuntime
import HTTPTypes

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

// https://developer.hashicorp.com/vault/api-docs#http-status-codes
public enum VaultServerError: Error {
    /// Invalid request, missing or invalid data.
    case invalidRequest(errors: String?)

    ///  Forbidden, your authentication details are either incorrect, you don't have access to this feature, or - if CORS is enabled - you made a cross-origin request from an origin that is not allowed to make such requests.
    case forbidden(errors: String?)

    /// Invalid path. This can both mean that the path truly doesn't exist or that you don't have permission to view a specific path. We use 404 in some cases to avoid state leakage. LIST requests with no results will also return 404s.
    case invalidPathOrPermissionDenied(errors: String?)

    /// Unsupported operation. You tried to use a method inappropriate to the request path, e.g. a POST on an endpoint that only accepts GETs.
    case unsupportedOperation(errors: String?)

    /// Internal server error. An internal error has occurred, try again later. If the error persists, report a bug.
    case InternalServerError(errors: String?)

    /// Vault is not initialized.
    case VaultNotInitialized(errors: String?)

    /// A request to Vault required Vault making a request to a third party; the third party responded with an error of some kind.
    case thirdPartyError(errors: String?)

    /// Vault is down for maintenance or is currently sealed. Try again later.
    case VaultIsSealed(errors: String?)

    /// Undocumented error response
    case undocumentedError(Int, errors: String?)
}

struct VaultErrorBody: Decodable {
    let errors: [String]
}

func mapVaultError(statusCode: Int, payload: UndocumentedPayload) async -> VaultServerError {
    let errors: String?
    if let body = payload.body {
        do {
            //                    let errors = try await ArraySlice<UInt8>(collecting: body, upTo: 1024*1024)
            let data = try await Data(collecting: body, upTo: 1024*1024)
            errors = try JSONDecoder().decode(VaultErrorBody.self, from: data).errors.joined(separator: ", ")
        } catch {
            errors = nil
        }
    } else {
        errors = nil
    }
    switch statusCode {
        case 400:
            return VaultServerError.invalidRequest(errors: errors)
        case 403:
            return VaultServerError.forbidden(errors: errors)
        case 404:
            return VaultServerError.invalidPathOrPermissionDenied(errors: errors)
        case 405:
            return VaultServerError.unsupportedOperation(errors: errors)
        case 500:
            return VaultServerError.InternalServerError(errors: errors)
        case 501:
            return VaultServerError.VaultNotInitialized(errors: errors)
        case 502:
            return VaultServerError.thirdPartyError(errors: errors)
        case 503:
            return VaultServerError.VaultIsSealed(errors: errors)
        default:
            return VaultServerError.forbidden(errors: errors)
    }
}
