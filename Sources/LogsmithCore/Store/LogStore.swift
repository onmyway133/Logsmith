import Foundation
import Observation

@MainActor
@Observable
public final class LogStore {
    public static let defaultSortOrder = [KeyPathComparator(\HTTPLog.sequence)]

    public private(set) var logs: [HTTPLog] = []
    public private(set) var visibleLogs: [HTTPLog] = []
    public private(set) var methods: [String] = []
    public private(set) var hosts: [String] = []

    public var filter = LogFilter() {
        didSet { if filter != oldValue { rebuild() } }
    }

    public var sortOrder = LogStore.defaultSortOrder {
        didSet { if sortOrder != oldValue { rebuild() } }
    }

    @ObservationIgnored private var indexByID: [String: Int] = [:]
    @ObservationIgnored private var visibleIndexByID: [String: Int] = [:]
    @ObservationIgnored private var matches: @Sendable (HTTPLog) -> Bool = { _ in true }

    public init() {}

    public func log(id: HTTPLog.ID?) -> HTTPLog? {
        guard let id, let index = indexByID[id] else { return nil }
        return logs[index]
    }

    // Appends in place when possible so a steady stream of requests doesn't re-filter the whole list.
    public func ingest(_ entries: some Collection<NetworkLogEntry>) {
        guard !entries.isEmpty else { return }
        var appended: [Int] = []
        var updated: [Int] = []
        for entry in entries {
            if let index = indexByID[entry.traceId] {
                logs[index].merge(entry)
                updated.append(index)
            } else {
                indexByID[entry.traceId] = logs.count
                appended.append(logs.count)
                logs.append(HTTPLog(entry: entry, sequence: logs.count))
            }
        }
        refreshFacets(appended + updated)
        guard sortOrder == Self.defaultSortOrder else {
            rebuild()
            return
        }
        for index in updated {
            let log = logs[index]
            switch (visibleIndexByID[log.id], matches(log)) {
            case (let visibleIndex?, true):
                visibleLogs[visibleIndex] = log
            case (nil, false):
                continue
            default:
                rebuild()
                return
            }
        }
        for index in appended where matches(logs[index]) {
            visibleIndexByID[logs[index].id] = visibleLogs.count
            visibleLogs.append(logs[index])
        }
    }

    public func clear() {
        logs.removeAll()
        visibleLogs.removeAll()
        methods.removeAll()
        hosts.removeAll()
        indexByID.removeAll()
        visibleIndexByID.removeAll()
    }

    private func refreshFacets(_ indices: [Int]) {
        var newMethods = Set(methods)
        var newHosts = Set(hosts)
        for index in indices {
            newMethods.insert(logs[index].method)
            if !logs[index].host.isEmpty { newHosts.insert(logs[index].host) }
        }
        if newMethods.count != methods.count { methods = newMethods.sorted() }
        if newHosts.count != hosts.count { hosts = newHosts.sorted() }
    }

    private func rebuild() {
        matches = filter.matcher()
        var result = filter.isActive ? logs.filter(matches) : logs
        if sortOrder != Self.defaultSortOrder {
            result.sort(using: sortOrder)
        }
        visibleIndexByID = Dictionary(uniqueKeysWithValues: result.enumerated().map { ($1.id, $0) })
        visibleLogs = result
    }
}
