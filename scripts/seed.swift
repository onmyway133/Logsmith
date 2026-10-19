import Foundation

let port = CommandLine.arguments.dropFirst().first ?? "52525"
let endpoint = URL(string: "http://127.0.0.1:\(port)/log")!
var clock = Date().timeIntervalSince1970 - 120
var entries: [[String: Any]] = []

func call(
    _ method: String,
    _ url: String,
    status: Int? = nil,
    ms: Double = 120,
    request: Any? = nil,
    response: Any? = nil,
    error: String? = nil
) {
    let id = UUID().uuidString
    clock += Double.random(in: 0.2...2)
    var requestHeaders = ["Accept": "application/json", "User-Agent": "Demo/1.0"]
    var entry: [String: Any] = [
        "traceId": id,
        "timestamp": clock,
        "phase": "request",
        "method": method,
        "url": url,
    ]
    if let request {
        requestHeaders["Content-Type"] = "application/json"
        entry["requestBody"] = json(request)
    }
    entry["requestHeaders"] = requestHeaders
    entries.append(entry)
    guard status != nil || error != nil else { return }

    var result: [String: Any] = [
        "traceId": id,
        "timestamp": clock + ms / 1000,
        "phase": "response",
        "elapsedMs": ms,
    ]
    if let status {
        result["statusCode"] = status
        result["responseHeaders"] = ["Content-Type": "application/json", "Cache-Control": "no-cache"]
    }
    if let response { result["responseBody"] = json(response) }
    if let error { result["error"] = error }
    entries.append(result)
}

func json(_ object: Any) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: object) else { return "" }
    return String(decoding: data, as: UTF8.self)
}

let api = "https://api.example.com"
call("POST", "\(api)/v1/auth/token", status: 200, ms: 310, request: ["username": "jane", "password": "••••••"], response: ["accessToken": "eyJhbGciOi.redacted", "expiresIn": 3600])
call("GET", "\(api)/v1/me", status: 200, ms: 95, response: ["id": 42, "name": "Jane Appleseed", "email": "jane@example.com"])
call("GET", "\(api)/v1/projects?page=1&limit=20", status: 200, ms: 210, response: ["items": (1...20).map { ["id": $0, "name": "Project \($0)", "starred": $0 % 3 == 0] }, "next": 2])
call("GET", "https://cdn.example.com/avatars/42.png", status: 304, ms: 40)
call("PATCH", "\(api)/v1/projects/7", status: 200, ms: 180, request: ["name": "Renamed"], response: ["id": 7, "name": "Renamed"])
call("DELETE", "\(api)/v1/projects/99", status: 404, ms: 60, response: ["error": "not_found", "message": "Project 99 does not exist"])
call("POST", "\(api)/v1/uploads", status: 500, ms: 1840, request: ["file": "report.pdf"], response: ["error": "internal", "message": "Upload service unavailable"])
call("GET", "https://slow.example.com/v1/feed", ms: 30000, error: "The request timed out.")
call("PUT", "\(api)/v1/settings", status: 204, ms: 75, request: ["theme": "dark", "notifications": true])
call("GET", "\(api)/v1/notifications/stream")

var request = URLRequest(url: endpoint)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: entries)
do {
    let (_, response) = try await URLSession.shared.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    print(status == 204 ? "Sent \(entries.count) entries to \(endpoint)" : "Logsmith responded with \(status)")
} catch {
    print("Couldn't reach Logsmith at \(endpoint). Is it running?")
    exit(1)
}
