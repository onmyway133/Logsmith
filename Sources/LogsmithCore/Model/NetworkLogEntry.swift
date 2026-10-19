import Foundation

public struct NetworkLogEntry: Codable, Sendable, Equatable {
    public enum Phase: String, Codable, Sendable {
        case request, response
    }

    public var traceId: String
    public var timestamp: Double
    public var phase: Phase
    public var method: String
    public var url: String
    public var requestHeaders: [String: String]
    public var requestBody: String?
    public var statusCode: Int?
    public var responseHeaders: [String: String]?
    public var responseBody: String?
    public var elapsedMs: Double?
    public var error: String?

    public init(
        traceId: String,
        timestamp: Double,
        phase: Phase,
        method: String,
        url: String,
        requestHeaders: [String: String] = [:],
        requestBody: String? = nil,
        statusCode: Int? = nil,
        responseHeaders: [String: String]? = nil,
        responseBody: String? = nil,
        elapsedMs: Double? = nil,
        error: String? = nil
    ) {
        self.traceId = traceId
        self.timestamp = timestamp
        self.phase = phase
        self.method = method
        self.url = url
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.elapsedMs = elapsedMs
        self.error = error
    }

    // Every field is optional on the wire so clients can send only what they have.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        traceId = try container.decodeIfPresent(String.self, forKey: .traceId) ?? UUID().uuidString
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp) ?? Date().timeIntervalSince1970
        phase = try container.decodeIfPresent(Phase.self, forKey: .phase) ?? .request
        method = try container.decodeIfPresent(String.self, forKey: .method) ?? "GET"
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        requestHeaders = try container.decodeIfPresent([String: String].self, forKey: .requestHeaders) ?? [:]
        requestBody = try container.decodeIfPresent(String.self, forKey: .requestBody)
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        responseHeaders = try container.decodeIfPresent([String: String].self, forKey: .responseHeaders)
        responseBody = try container.decodeIfPresent(String.self, forKey: .responseBody)
        elapsedMs = try container.decodeIfPresent(Double.self, forKey: .elapsedMs)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    public static func decode(_ data: Data) -> [NetworkLogEntry] {
        let decoder = JSONDecoder()
        if let entry = try? decoder.decode(NetworkLogEntry.self, from: data) {
            return [entry]
        }
        return (try? decoder.decode([NetworkLogEntry].self, from: data)) ?? []
    }
}
