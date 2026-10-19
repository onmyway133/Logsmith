import Foundation
import NIOCore
import NIOHTTP1

final class HTTPChannelHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    static let maxBodySize = 64 * 1024 * 1024

    private let buffer: IngestBuffer<NetworkLogEntry>
    private var head: HTTPRequestHead?
    private var body: ByteBuffer?
    private var isTooLarge = false

    init(buffer: IngestBuffer<NetworkLogEntry>) {
        self.buffer = buffer
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            self.head = head
            body = context.channel.allocator.buffer(capacity: 0)
            isTooLarge = false
        case .body(var chunk):
            guard !isTooLarge else { return }
            if (body?.readableBytes ?? 0) + chunk.readableBytes > Self.maxBodySize {
                isTooLarge = true
                body = nil
            } else {
                body?.writeBuffer(&chunk)
            }
        case .end:
            respond(handle(), context: context)
            head = nil
            body = nil
        }
    }

    private func handle() -> HTTPResponseStatus {
        guard let head else { return .badRequest }
        let path = head.uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? head.uri
        switch (head.method, path) {
        case (.GET, "/health"):
            return .ok
        case (.POST, "/log"):
            guard !isTooLarge else { return .payloadTooLarge }
            guard let body, body.readableBytes > 0 else { return .badRequest }
            let entries = NetworkLogEntry.decode(Data(body.readableBytesView))
            guard !entries.isEmpty else { return .unprocessableEntity }
            buffer.append(contentsOf: entries)
            return .noContent
        case (_, "/log"), (_, "/health"):
            return .methodNotAllowed
        default:
            return .notFound
        }
    }

    private func respond(_ status: HTTPResponseStatus, context: ChannelHandlerContext) {
        let keepAlive = head?.isKeepAlive ?? false
        var headers = HTTPHeaders([("Content-Length", "0")])
        headers.add(name: "Connection", value: keepAlive ? "keep-alive" : "close")
        let responseHead = HTTPResponseHead(version: head?.version ?? .http1_1, status: status, headers: headers)
        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
        let done = context.writeAndFlush(wrapOutboundOut(.end(nil)))
        if !keepAlive {
            let channel = context.channel
            done.whenComplete { _ in
                channel.close(promise: nil)
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        context.close(promise: nil)
    }
}
