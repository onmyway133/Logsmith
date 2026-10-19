import NIOCore
import NIOHTTP1
import NIOPosix
import Synchronization

public final class LogServer: Sendable {
    public let host: String
    public let port: Int
    private let buffer: IngestBuffer<NetworkLogEntry>
    private let channel = Mutex<(any Channel)?>(nil)

    public init(host: String = "127.0.0.1", port: Int, buffer: IngestBuffer<NetworkLogEntry>) {
        self.host = host
        self.port = port
        self.buffer = buffer
    }

    public func start() async throws {
        let buffer = buffer
        let bootstrap = ServerBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.configureHTTPServerPipeline(withErrorHandling: true)
                    try channel.pipeline.syncOperations.addHandler(HTTPChannelHandler(buffer: buffer))
                }
            }
            .childChannelOption(.maxMessagesPerRead, value: 16)
        let bound = try await bootstrap.bind(host: host, port: port).get()
        channel.withLock { $0 = bound }
    }

    public func stop() async {
        let current = channel.withLock { channel in
            defer { channel = nil }
            return channel
        }
        try? await current?.close().get()
    }
}
