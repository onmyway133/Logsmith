import Testing
@testable import LogsmithCore

@MainActor
struct LogStoreTests {
    private func request(_ id: String, _ method: String = "GET", _ url: String = "https://api.example.com/users") -> NetworkLogEntry {
        NetworkLogEntry(traceId: id, timestamp: 1, phase: .request, method: method, url: url)
    }

    private func response(_ id: String, _ status: Int?, error: String? = nil) -> NetworkLogEntry {
        NetworkLogEntry(traceId: id, timestamp: 2, phase: .response, method: "GET", url: "", statusCode: status, elapsedMs: 42, error: error)
    }

    @Test func mergesResponseIntoRequestInEitherOrder() {
        let store = LogStore()
        store.ingest([response("a", 404), request("a", "POST")])
        store.ingest([request("b")])
        store.ingest([response("b", nil, error: "The request timed out.")])
        #expect(store.logs.count == 2)
        #expect(store.logs[0].method == "POST")
        #expect(store.logs[0].host == "api.example.com")
        #expect(store.logs[0].statusClass == .clientError)
        #expect(store.logs[1].statusClass == .failed)
    }

    @Test func filtersAndUpdatesVisibleLogs() {
        let store = LogStore()
        store.ingest([request("a", "GET", "https://cdn.example.com/a.png"), request("b", "POST")])
        store.filter.text = "png"
        #expect(store.visibleLogs.map(\.id) == ["a"])
        store.filter = LogFilter(hosts: ["api.example.com"])
        #expect(store.visibleLogs.map(\.id) == ["b"])
        store.filter = LogFilter(statusClasses: [.pending])
        store.ingest([response("a", 200)])
        #expect(store.visibleLogs.map(\.id) == ["b"])
    }
}
