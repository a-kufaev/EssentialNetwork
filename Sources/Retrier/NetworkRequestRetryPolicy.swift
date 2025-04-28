//===----------------------------------------------------------------------===//
//
// This source file is part of the EssentialNetwork open source project
//
// Copyright (c) 2025 Artem Kufaev
// Licensed under MIT License
//
// See https://github.com/a-kufaev/EssentialNetwork/blob/main/LICENSE for license information
//
//===----------------------------------------------------------------------===//

import Foundation

// swiftlint:disable file_length

/// A retry policy with exponential backoff.
///
/// Used to retry requests for the allowed HTTP methods,
/// status codes, and network errors.
open class NetworkRequestRetryPolicy: @unchecked Sendable, NetworkRequestInterceptor {
    
    /// The default number of retries (not counting the first attempt).
    public static let defaultRetryLimit: UInt = 2

    /// The exponent base (must be at least 2).
    public static let defaultExponentialBackoffBase: UInt = 2

    /// The multiplier that controls the pause duration.
    public static let defaultExponentialBackoffScale: Double = 0.5

    /// The HTTP methods for which retries are allowed by default.
    /// See [RFC 2616 §9.1.2](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html).
    public static let defaultRetryableHTTPMethods: Set<HTTPMethod> = [
        .delete, // [Delete](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.7) - not always idempotent
        .get, // [GET](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.3) - generally idempotent
        .head, // [HEAD](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.4) - generally idempotent
        .put, // [PUT](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.6) - not always idempotent
    ]

    /// The HTTP response codes for which it is safe to retry the request.
    /// See [RFC 2616 §10](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html).
    public static let defaultRetryableHTTPStatusCodes: Set<Int> = [
        408, // [Request Timeout](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.9)
        500, // [Internal Server Error](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.1)
        502, // [Bad Gateway](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.3)
        503, // [Service Unavailable](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.4)
        504 // [Gateway Timeout](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.5.5)
    ]

    /// The `URLError` codes for which retrying the request makes sense (the list is based on Alamofire).
    public static let defaultRetryableURLErrorCodes: Set<URLError.Code> =
        [ // [Security] App Transport Security blocked the connection because there is no secure channel.
            //   - [Disabled] ATS settings cannot be changed at runtime.
            // .appTransportSecurityRequiresSecureConnection,

            // [System] The app tried to use a background session already bound to another process.
            //   - [Enabled] The other process may release the session, so a retry can help.
            .backgroundSessionInUseByAnotherProcess,
        
            // [System] The session configuration requires a shared container identifier, but none is set.
            //   - [Disabled] Cannot be changed at runtime.
            // .backgroundSessionRequiresSharedContainer,

            // [System] The app was terminated or suspended during a background download.
            //   - [Enabled] A retry is possible after returning to the active state.
            .backgroundSessionWasDisconnected,
        
            // [Network] URLSession received invalid data.
            //   - [Enabled] The server may respond correctly on retry.
            .badServerResponse,
        
            // [Resource] An invalid URL prevented the request from being sent.
            //   - [Disabled] The URL is most likely malformed.
            // .badURL,

            // [System] A connection attempt during a phone call on a network without simultaneous data transfer.
            //   - [Enabled] The connection will be restored after the call ends.
            .callIsActive,
        
            // [Client] The asynchronous load was cancelled.
            //   - [Disabled] The request was cancelled explicitly.
            // .cancelled,

            // [FS] The download task could not close the file.
            //   - [Disabled] A filesystem error will not disappear on retry.
            // .cannotCloseFile,

            // [Network] Could not connect to the host.
            //   - [Enabled] The server/DNS may recover.
            .cannotConnectToHost,
        
            // [FS] Could not create the file due to an I/O error.
            //   - [Disabled] A hardware error will persist.
            // .cannotCreateFile,

            // [Data] Received data in an unknown encoding.
            //   - [Disabled] The server is unlikely to change the format.
            // .cannotDecodeContentData,

            // [Data] Could not decode the data even with a known format.
            //   - [Disabled] A retry will not help.
            // .cannotDecodeRawData,

            // [Network] Cannot resolve the host name.
            //   - [Enabled] DNS may recover.
            .cannotFindHost,
        
            // [Network] A "cache-only" request was not served.
            //   - [Enabled] The cache may be populated on retry.
            .cannotLoadFromNetwork,
        
            // [FS] Could not move the downloaded file.
            //   - [Disabled] The filesystem error will likely persist.
            // .cannotMoveFile,

            // [FS] Could not open the file.
            //   - [Disabled] Filesystem error.
            // .cannotOpenFile,

            // [Data] Cannot parse the response.
            //   - [Disabled] A retry rarely helps.
            // .cannotParseResponse,

            // [FS] Could not remove the file.
            //   - [Disabled] Filesystem problem.
            // .cannotRemoveFile,

            // [FS] Could not write the file.
            //   - [Disabled] Filesystem error.
            // .cannotWriteToFile,

            // [Security] The client certificate was rejected.
            //   - [Disabled] The certificate will not change.
            // .clientCertificateRejected,

            // [Security] A client certificate is required.
            //   - [Disabled] A retry will not help.
            // .clientCertificateRequired,

            // [Data] The resource size exceeds the allowed maximum.
            //   - [Disabled] The limit will remain.
            // .dataLengthExceedsMaximum,

            // [System] The cellular network blocked the connection.
            //   - [Enabled] Can switch to Wi‑Fi.
            .dataNotAllowed,
        
            // [Network] The host address was not found via DNS.
            //   - [Enabled] DNS may recover.
            .dnsLookupFailed,
        
            // [Data] A file decoding error during the download.
            //   - [Enabled] The server may fix the problem.
            .downloadDecodingFailedMidStream,
        
            // [Data] A decoding error after the download.
            //   - [Enabled] A retry may yield a correct file.
            .downloadDecodingFailedToComplete,
        
            // [FS] The file is missing.
            //   - [Disabled] A retry will change nothing.
            // .fileDoesNotExist,

            // [FS] The requested FTP resource turned out to be a directory.
            //   - [Disabled] The resource type will not change.
            // .fileIsDirectory,

            // [Network] A redirect loop was detected or the limit (16) was exceeded.
            //   - [Disabled] The loop will not disappear.
            // .httpTooManyRedirects,

            // [System] The connection requires roaming, but it is disabled.
            //   - [Enabled] Can switch to Wi‑Fi.
            .internationalRoamingOff,
        
            // [Connection] The connection was dropped during transfer.
            //   - [Enabled] A retry may restore the session.
            .networkConnectionLost,
        
            // [FS] Insufficient permissions to read the resource.
            //   - [Disabled] Permissions will not appear automatically.
            // .noPermissionsToReadFile,

            // [Connection] The internet connection is not established and cannot be brought up automatically.
            //   - [Enabled] The user may restore the network.
            .notConnectedToInternet,
        
            // [Resource] The server reported a redirect but did not provide a URL.
            //   - [Disabled] A retry will not add the address.
            // .redirectToNonExistentLocation,

            // [Client] A body stream is required, but it was not provided.
            //   - [Disabled] The client must fix the code.
            // .requestBodyStreamExhausted,

            // [Resource] The resource is unavailable.
            //   - [Disabled] The situation will most likely not change quickly.
            // .resourceUnavailable,

            // [Security] Could not establish a secure connection (reason unclear).
            //   - [Enabled] A retry may restore SSL.
            .secureConnectionFailed,
        
            // [Security] The server certificate is expired or not yet valid.
            //   - [Enabled] The certificate may become valid (for example, after time synchronization).
            .serverCertificateHasBadDate,
        
            // [Security] The certificate is not signed by a trusted CA.
            //   - [Disabled] The situation will not change on retry.
            // .serverCertificateHasUnknownRoot,

            // [Security] The certificate is not yet in effect.
            //   - [Enabled] The certificate may become valid.
            .serverCertificateNotYetValid,
        
            // [Security] The certificate is signed by an untrusted CA.
            //   - [Disabled] Will not change without manual action.
            // .serverCertificateUntrusted,

            // [Network] The asynchronous operation finished with a timeout.
            //   - [Enabled] The cause of the timeout may have been temporary.
            .timedOut

            // [System] URL Loading encountered an error that cannot be interpreted.
            //   - [Disabled] A retry is pointless.
            // .unknown,

            // [Resource] A valid URL is not supported by the framework.
            //   - [Disabled] Nothing will change.
            // .unsupportedURL,

            // [Client] Authentication is required.
            //   - [Disabled] The user must provide credentials.
            // .userAuthenticationRequired,

            // [Client] The user cancelled authentication.
            //   - [Disabled] A retry contradicts the explicit action.
            // .userCancelledAuthentication,

            // [Resource] The server declared a non-zero size but closed the connection without data.
            //   - [Disabled] The situation will recur.
            // .zeroByteResource,
        ]
    /// The maximum number of retries.
    public let retryLimit: UInt

    /// The exponent base (at least 2).
    public let exponentialBackoffBase: UInt

    /// The exponential backoff multiplier.
    public let exponentialBackoffScale: Double

    /// The HTTP methods for which retries are allowed.
    public let retryableHTTPMethods: Set<HTTPMethod>

    /// The HTTP statuses for which a retry is performed.
    public let retryableHTTPStatusCodes: Set<Int>

    /// The network errors (URLError) for which a retry is expected.
    public let retryableURLErrorCodes: Set<URLError.Code>

    /// Creates a `RetryPolicy` with the given parameters.
    ///
    /// - Parameters:
    ///   - retryLimit: the allowed number of retries (default 2).
    ///   - exponentialBackoffBase: the base of the backoff exponent (default 2).
    ///   - exponentialBackoffScale: the backoff multiplier (default 0.5).
    ///   - retryableHTTPMethods: the set of HTTP methods for which retries are allowed.
    ///   - retryableHTTPStatusCodes: the HTTP statuses that require a retry.
    ///   - retryableURLErrorCodes: the `URLError` codes for which a retry is performed.
    public init(
        retryLimit: UInt = NetworkRequestRetryPolicy.defaultRetryLimit,
        exponentialBackoffBase: UInt = NetworkRequestRetryPolicy.defaultExponentialBackoffBase,
        exponentialBackoffScale: Double = NetworkRequestRetryPolicy.defaultExponentialBackoffScale,
        retryableHTTPMethods: Set<HTTPMethod> = NetworkRequestRetryPolicy.defaultRetryableHTTPMethods,
        retryableHTTPStatusCodes: Set<Int> = NetworkRequestRetryPolicy.defaultRetryableHTTPStatusCodes,
        retryableURLErrorCodes: Set<URLError.Code> = NetworkRequestRetryPolicy.defaultRetryableURLErrorCodes
    ) {
        precondition(exponentialBackoffBase >= 2, "The exponential backoff base must be at least 2.")

        self.retryLimit = retryLimit
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
        self.retryableHTTPMethods = retryableHTTPMethods
        self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
        self.retryableURLErrorCodes = retryableURLErrorCodes
    }

    /// Returns the retry strategy (taking the attempt number into account).
    open func retry(
        _ context: NetworkRequestRetryContext,
        dueTo _: any Error
    ) async -> NetworkRequestRetryResult {
        .retryWithDelay(
            pow(Double(exponentialBackoffBase), Double(context.request.retryAttempts)) * exponentialBackoffScale
        )
    }

    /// Determines whether the specified request should be retried.
    ///
    /// - Parameters:
    ///   - request: the request that failed with an error.
    ///   - error: the error that caused the request to fail.
    ///
    /// - Returns: `true` if a retry is allowed.
    open func shouldRetry(context: NetworkRequestRetryContext, dueTo error: any Error) -> Bool {
        guard context.request.retryAttempts < retryLimit else { return false }
        
        guard let httpMethod = context.request.currentRequest.httpMethod,
              retryableHTTPMethods.contains(HTTPMethod(rawValue: httpMethod))
        else { return false }

        if let response = context.response,
           retryableHTTPStatusCodes.contains(response.statusCode) {
            return true
        }
        
        let errorCode = (error as? URLError)?.code
        let networkErrorCode = ((error as? NetworkError)?.underlyingError as? URLError)?.code

        guard let code = errorCode ?? networkErrorCode else { return false }

        return retryableURLErrorCodes.contains(code)
    }
}

extension NetworkRequestInterceptor where Self == NetworkRequestRetryPolicy {
    
    /// Returns the standard retry policy.
    public static var retryPolicy: NetworkRequestRetryPolicy {
        NetworkRequestRetryPolicy()
    }

    /// Creates a retry policy with custom parameters (see `NetworkRequestRetryPolicy.init`).
    ///
    /// - Parameters:
    ///   - retryLimit: the maximum allowed number of retries.
    ///   - exponentialBackoffBase: the base of the backoff exponent.
    ///   - exponentialBackoffScale: the backoff multiplier.
    ///   - retryableHTTPMethods: the list of HTTP methods for which retries are needed.
    ///   - retryableHTTPStatusCodes: the HTTP statuses for which a retry should be performed.
    ///   - retryableURLErrorCodes: the set of `URLError` codes that trigger a retry.
    ///
    /// - Returns: a configured `RetryPolicy`.
    public static func retryPolicy(
        retryLimit: UInt = NetworkRequestRetryPolicy.defaultRetryLimit,
        exponentialBackoffBase: UInt = NetworkRequestRetryPolicy.defaultExponentialBackoffBase,
        exponentialBackoffScale: Double = NetworkRequestRetryPolicy.defaultExponentialBackoffScale,
        retryableHTTPMethods: Set<HTTPMethod> = NetworkRequestRetryPolicy.defaultRetryableHTTPMethods,
        retryableHTTPStatusCodes: Set<Int> = NetworkRequestRetryPolicy.defaultRetryableHTTPStatusCodes,
        retryableURLErrorCodes: Set<URLError.Code> = NetworkRequestRetryPolicy.defaultRetryableURLErrorCodes
    ) -> NetworkRequestRetryPolicy {
        NetworkRequestRetryPolicy(
            retryLimit: retryLimit,
            exponentialBackoffBase: exponentialBackoffBase,
            exponentialBackoffScale: exponentialBackoffScale,
            retryableHTTPMethods: retryableHTTPMethods,
            retryableHTTPStatusCodes: retryableHTTPStatusCodes,
            retryableURLErrorCodes: retryableURLErrorCodes
        )
    }
}

// MARK: - ConnectionLostRetryPolicy

/// A policy that automatically retries idempotent requests when the connection is lost.
/// For details, see [Apple QA1941](https://developer.apple.com/library/content/qa/qa1941/_index.html).
open class ConnectionLostRetryPolicy: NetworkRequestRetryPolicy, @unchecked Sendable {

    /// Creates a policy for connection recovery with backoff exponent parameters.
    ///
    /// - Parameters:
    ///   - retryLimit: the number of retry attempts (default `defaultRetryLimit`).
    ///   - exponentialBackoffBase: the exponent base (`defaultExponentialBackoffBase`).
    ///   - exponentialBackoffScale: the backoff multiplier (`defaultExponentialBackoffScale`).
    ///   - retryableHTTPMethods: the idempotent HTTP methods that can be retried.
    public init(
        retryLimit: UInt = NetworkRequestRetryPolicy.defaultRetryLimit,
        exponentialBackoffBase: UInt = NetworkRequestRetryPolicy.defaultExponentialBackoffBase,
        exponentialBackoffScale: Double = NetworkRequestRetryPolicy.defaultExponentialBackoffScale,
        retryableHTTPMethods: Set<HTTPMethod> = NetworkRequestRetryPolicy.defaultRetryableHTTPMethods
    ) {
        super.init(
            retryLimit: retryLimit,
            exponentialBackoffBase: exponentialBackoffBase,
            exponentialBackoffScale: exponentialBackoffScale,
            retryableHTTPMethods: retryableHTTPMethods,
            retryableHTTPStatusCodes: [],
            retryableURLErrorCodes: [.networkConnectionLost]
        )
    }
}

extension NetworkRequestInterceptor where Self == ConnectionLostRetryPolicy {
    
    /// Returns the default policy for handling `.networkConnectionLost`.
    public static var connectionLostRetryPolicy: ConnectionLostRetryPolicy {
        ConnectionLostRetryPolicy()
    }

    /// Creates a `ConnectionLostRetryPolicy` instance with custom parameters.
    ///
    /// - Parameters:
    ///   - retryLimit: the allowed number of retries (default `defaultRetryLimit`).
    ///   - exponentialBackoffBase: the exponent base (`defaultExponentialBackoffBase`).
    ///   - exponentialBackoffScale: the backoff multiplier (`defaultExponentialBackoffScale`).
    ///   - retryableHTTPMethods: the list of idempotent HTTP methods for retries.
    public static func connectionLostRetryPolicy(
        retryLimit: UInt = NetworkRequestRetryPolicy.defaultRetryLimit,
        exponentialBackoffBase: UInt = NetworkRequestRetryPolicy.defaultExponentialBackoffBase,
        exponentialBackoffScale: Double = NetworkRequestRetryPolicy.defaultExponentialBackoffScale,
        retryableHTTPMethods: Set<HTTPMethod> = NetworkRequestRetryPolicy.defaultRetryableHTTPMethods
    ) -> ConnectionLostRetryPolicy {
        ConnectionLostRetryPolicy(
            retryLimit: retryLimit,
            exponentialBackoffBase: exponentialBackoffBase,
            exponentialBackoffScale: exponentialBackoffScale,
            retryableHTTPMethods: retryableHTTPMethods
        )
    }
}

// swiftlint:enable file_length
