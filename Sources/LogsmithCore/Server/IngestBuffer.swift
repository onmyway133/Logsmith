import Synchronization

// Batches entries from NIO event loops so a burst of requests causes one UI update, not hundreds.
public final class IngestBuffer<Element: Sendable>: Sendable {
    private struct State {
        var pending: [Element] = []
        var isScheduled = false
    }

    private let state = Mutex(State())
    private let interval: Duration
    private let flush: @MainActor @Sendable ([Element]) -> Void

    public init(interval: Duration = .milliseconds(100), flush: @escaping @MainActor @Sendable ([Element]) -> Void) {
        self.interval = interval
        self.flush = flush
    }

    public func append(contentsOf entries: [Element]) {
        guard !entries.isEmpty else { return }
        let shouldSchedule = state.withLock { state in
            state.pending.append(contentsOf: entries)
            defer { state.isScheduled = true }
            return !state.isScheduled
        }
        guard shouldSchedule else { return }
        Task {
            try? await Task.sleep(for: interval)
            let batch = state.withLock { state in
                defer {
                    state.pending.removeAll(keepingCapacity: true)
                    state.isScheduled = false
                }
                return state.pending
            }
            await flush(batch)
        }
    }
}
