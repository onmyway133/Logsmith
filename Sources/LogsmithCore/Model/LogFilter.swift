import Foundation

public struct LogFilter: Equatable, Sendable {
    public var text = ""
    public var methods: Set<String> = []
    public var hosts: Set<String> = []
    public var statusClasses: Set<StatusClass> = []
    public var includeBodies = false

    public init(
        text: String = "",
        methods: Set<String> = [],
        hosts: Set<String> = [],
        statusClasses: Set<StatusClass> = [],
        includeBodies: Bool = false
    ) {
        self.text = text
        self.methods = methods
        self.hosts = hosts
        self.statusClasses = statusClasses
        self.includeBodies = includeBodies
    }

    public var isActive: Bool {
        !tokens.isEmpty || hasMenuFilters
    }

    public var hasMenuFilters: Bool {
        !methods.isEmpty || !hosts.isEmpty || !statusClasses.isEmpty || includeBodies
    }

    var tokens: [String] {
        text.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
    }

    public func matcher() -> @Sendable (HTTPLog) -> Bool {
        let tokens = tokens
        let methods = methods
        let hosts = hosts
        let statusClasses = statusClasses
        let includeBodies = includeBodies
        return { log in
            if !methods.isEmpty, !methods.contains(log.method) { return false }
            if !hosts.isEmpty, !hosts.contains(log.host) { return false }
            if !statusClasses.isEmpty, !statusClasses.contains(log.statusClass) { return false }
            for token in tokens {
                if log.searchKey.contains(token) { continue }
                guard includeBodies else { return false }
                let inBody = [log.requestBody, log.responseBody].contains { body in
                    body?.range(of: token, options: .caseInsensitive) != nil
                }
                if !inBody { return false }
            }
            return true
        }
    }
}
