# EssentialNetwork

A lightweight, dependency-free networking layer for Swift, built on top of `URLSession` with modern Swift concurrency, typed errors, and a fluent response-serialization DSL.

## Features

- 🌐 **URLSession-based** — a thin, transparent layer over `URLSession`, no magic
- ⚡️ **Swift Concurrency** — `async`/`await` throughout, `Sendable`-safe
- 🎯 **Typed errors** — every API uses `throws(NetworkError)` for precise error handling
- 🧩 **Data / Upload / Download requests** with full lifecycle control (`resume`, `suspend`, `cancel`)
- 🔌 **Interceptors** — adapt outgoing requests and drive custom retry logic
- 🔁 **Retry policy** — configurable exponential backoff out of the box
- 📡 **Event monitors** — observe the full request lifecycle for logging/metrics
- 📦 **Multipart form-data** — a composable `MultipartDataBuilder`
- 🧪 **Testing support** — a separate `EssentialNetworkTesting` library with `Equatable` conformances and helpers
- 🪶 **Zero dependencies** — only `Foundation`

## Requirements

- Swift 6.0+
- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+ / visionOS 1.0+

## Installation

### Swift Package Manager

Add EssentialNetwork to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/a-kufaev/EssentialNetwork.git", from: "1.0.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "MyApp",
    dependencies: ["EssentialNetwork"]
)
```

## Quick Start

```swift
import EssentialNetwork

let session = NetworkSession()

let dataRequest = try await session.request(
    URL(string: "https://api.example.com/users")!,
    method: .get,
    headers: ["Authorization": "Bearer token"],
    parameters: ["page": "1"],
    interceptor: nil
)

dataRequest
    .responseDecodable(of: [User].self) { result in
        switch result {
        case let .success(users):
            print("Loaded \(users.count) users")
        case let .failure(error):
            print("Failed: \(error)")
        }
    }
    .resume()
```

## Sending a JSON body

```swift
struct CreateUser: Encodable {
    let name: String
    let email: String
}

let dataRequest = try await session.request(
    URL(string: "https://api.example.com/users")!,
    method: .post,
    headers: nil,
    body: CreateUser(name: "John", email: "john@example.com"),
    encoder: nil,
    interceptor: nil
)

dataRequest
    .responseDecodable(of: User.self) { result in
        // Handle the decoded model
    }
    .resume()
```

## Response serialization

`DataRequest` exposes a fluent DSL for handling responses:

```swift
dataRequest.responseData { result in /* Result<NetworkResponse, NetworkError> */ }
dataRequest.responseDecodable(of: User.self) { result in /* Result<User, NetworkError> */ }
```

Each serialization call returns the request, so you can chain and then `.resume()`.

## Multipart form-data

Build a multipart payload with the fluent `MultipartDataBuilder` and upload it in a single call:

```swift
let uploadRequest = try await session.upload(
    multipartDataBuilder: { builder in
        builder
            .addText(name: "username", value: "john_doe")
            .addFile(name: "avatar", filename: "photo.jpg", contentType: .jpeg, data: imageData)
    },
    to: URL(string: "https://api.example.com/upload")!,
    method: .post,
    headers: nil,
    boundary: nil,
    interceptor: nil
)
```

You can also build a `MultipartDataContainer` directly:

```swift
let container = MultipartDataBuilder()
    .addText(name: "title", value: "My Document")
    .addFile(name: "document", filename: "report.pdf", contentType: .pdf, data: pdfData)
    .build()
```

## Interceptors & retries

`NetworkRequestInterceptor` composes `NetworkRequestAdapter` (modify outgoing requests, e.g. inject auth) and `NetworkRequestRetrier` (decide whether/how to retry on failure). Both have default implementations, so you only override what you need:

```swift
struct AuthInterceptor: NetworkRequestInterceptor {
    func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        var request = urlRequest
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    func shouldRetry(context: NetworkRequestRetryContext, dueTo error: any Error) -> Bool {
        // your retry decision
        false
    }
}
```

A ready-made exponential-backoff retrier is available via `NetworkRequestRetryPolicy`.

## Event monitoring

Implement `NetworkEventMonitor` to observe the request lifecycle (request creation, adaptation, completion, etc.) — useful for logging, analytics, and debugging. Pass monitors when creating the session:

```swift
let session = NetworkSession(eventMonitors: [MyLoggingMonitor()])
```

## Error handling

All requests fail with a typed `NetworkError`, covering invalid URLs, body encoding, request adaptation, execution, response decoding, unsuccessful HTTP statuses, cancellation, and multipart errors.

## Testing

The package ships a separate `EssentialNetworkTesting` library that provides `Equatable` conformances for the error types and test helpers (such as an `InputStream` mock), making it easy to assert on networking behavior in your own test target:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["MyApp", "EssentialNetworkTesting"]
)
```

## License

EssentialNetwork is available under the MIT license. See the [LICENSE](https://github.com/a-kufaev/EssentialNetwork/blob/main/LICENSE) file for more info.
