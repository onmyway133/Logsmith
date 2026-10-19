import Foundation
import Observation

@MainActor
@Observable
public final class ServerController {
    public enum State: Equatable, Sendable {
        case stopped
        case starting
        case running
        case failed(String)
    }

    public static let defaultPort = 52525

    public private(set) var state = State.stopped
    public private(set) var port: Int

    @ObservationIgnored private var server: LogServer?
    @ObservationIgnored private let buffer: IngestBuffer<NetworkLogEntry>

    public init(port: Int = ServerController.defaultPort, ingest: @escaping @MainActor @Sendable ([NetworkLogEntry]) -> Void) {
        self.port = port
        buffer = IngestBuffer(flush: ingest)
    }

    public var isRunning: Bool { state == .running }

    public var endpoint: String { "http://127.0.0.1:\(port)/log" }

    public var errorMessage: String? {
        if case .failed(let message) = state { message } else { nil }
    }

    public func start() async {
        guard server == nil else { return }
        state = .starting
        let server = LogServer(port: port, buffer: buffer)
        do {
            try await server.start()
            self.server = server
            state = .running
        } catch {
            state = .failed("Couldn't listen on port \(port). \(error.localizedDescription)")
        }
    }

    public func stop() async {
        let server = server
        self.server = nil
        await server?.stop()
        state = .stopped
    }

    public func toggle() async {
        if server == nil {
            await start()
        } else {
            await stop()
        }
    }

    public func restart(port: Int) async {
        await stop()
        self.port = port
        await start()
    }

    public func dismissError() {
        if errorMessage != nil { state = .stopped }
    }
}
