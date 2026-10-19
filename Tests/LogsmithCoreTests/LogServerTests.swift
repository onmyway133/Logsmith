import Foundation
import Synchronization
import Testing
@testable import LogsmithCore

@MainActor
struct LogServerTests {
    private func post(_ body: String, port: Int) async throws -> Int {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/log")!)
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }

    @Test func ingestsPostedEntries() async throws {
        let received = Mutex<[NetworkLogEntry]>([])
        let controller = ServerController(port: 52_599) { entries in
            received.withLock { $0.append(contentsOf: entries) }
        }
        await controller.start()
        #expect(controller.isRunning)

        #expect(try await post(#"{"traceId":"a","url":"https://example.com","error":"timed out"}"#, port: 52_599) == 204)
        #expect(try await post(#"[{"traceId":"b","phase":"response","statusCode":200}]"#, port: 52_599) == 204)
        #expect(try await post("nope", port: 52_599) == 422)

        try await Task.sleep(for: .milliseconds(300))
        let entries = received.withLock { $0 }
        #expect(entries.map(\.traceId) == ["a", "b"])
        #expect(entries.first?.method == "GET")
        #expect(entries.first?.error == "timed out")
        await controller.stop()
    }
}
