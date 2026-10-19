import Foundation

extension HTTPLog {
    public var curlCommand: String {
        var parts = ["curl", "-X", method, Self.quote(url)]
        for (name, value) in requestHeaders.sorted(by: { $0.key < $1.key }) {
            parts += ["-H", Self.quote("\(name): \(value)")]
        }
        if let requestBody, !requestBody.isEmpty {
            parts += ["--data-raw", Self.quote(requestBody)]
        }
        return parts.joined(separator: " ")
    }

    private static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
