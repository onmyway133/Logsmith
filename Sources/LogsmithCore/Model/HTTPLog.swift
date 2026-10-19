import Foundation

public struct HTTPLog: Identifiable, Sendable, Equatable {
    public let id: String
    public let sequence: Int
    public private(set) var revision = 0
    public private(set) var date: Date
    public private(set) var method: String
    public private(set) var url: String
    public private(set) var host: String
    public private(set) var path: String
    public private(set) var requestHeaders: [String: String]
    public private(set) var requestBody: String?
    public private(set) var statusCode: Int?
    public private(set) var responseHeaders: [String: String]?
    public private(set) var responseBody: String?
    public private(set) var elapsedMs: Double?
    public private(set) var error: String?
    public private(set) var searchKey = ""

    public init(entry: NetworkLogEntry, sequence: Int) {
        id = entry.traceId
        self.sequence = sequence
        date = Date(timeIntervalSince1970: entry.timestamp)
        method = entry.method.uppercased()
        url = entry.url
        (host, path) = Self.split(entry.url)
        requestHeaders = entry.requestHeaders
        requestBody = entry.requestBody
        apply(entry)
    }

    // A response can arrive before its request, so fill gaps instead of overwriting.
    public mutating func merge(_ entry: NetworkLogEntry) {
        if entry.phase == .request {
            date = Date(timeIntervalSince1970: entry.timestamp)
            method = entry.method.uppercased()
        }
        if requestHeaders.isEmpty { requestHeaders = entry.requestHeaders }
        if requestBody == nil { requestBody = entry.requestBody }
        if url.isEmpty, !entry.url.isEmpty {
            url = entry.url
            (host, path) = Self.split(entry.url)
        }
        apply(entry)
        revision += 1
    }

    private mutating func apply(_ entry: NetworkLogEntry) {
        if entry.phase == .response {
            statusCode = entry.statusCode
            responseHeaders = entry.responseHeaders
            responseBody = entry.responseBody
            elapsedMs = entry.elapsedMs
            error = entry.error
        }
        searchKey = [method, url, statusCode.map(String.init) ?? "", error ?? "", id]
            .joined(separator: " ")
            .lowercased()
    }

    public var statusClass: StatusClass { StatusClass(statusCode: statusCode, error: error) }
    public var isPending: Bool { statusClass == .pending }
    public var statusSortKey: Int { statusCode ?? -1 }
    public var elapsedSortKey: Double { elapsedMs ?? -1 }
    public var responseSize: Int { responseBody?.utf8.count ?? 0 }

    public static func == (lhs: HTTPLog, rhs: HTTPLog) -> Bool {
        lhs.id == rhs.id && lhs.revision == rhs.revision
    }

    private static func split(_ url: String) -> (String, String) {
        guard let components = URLComponents(string: url) else { return ("", url) }
        var path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        if let query = components.percentEncodedQuery { path += "?" + query }
        let host = components.host.map { host in
            components.port.map { "\(host):\($0)" } ?? host
        } ?? ""
        return (host, path)
    }
}
