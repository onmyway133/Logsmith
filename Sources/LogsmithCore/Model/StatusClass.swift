public enum StatusClass: String, CaseIterable, Sendable, Hashable, Identifiable {
    case pending
    case success
    case redirect
    case clientError
    case serverError
    case failed

    public var id: Self { self }

    public init(statusCode: Int?, error: String?) {
        switch statusCode {
        case nil: self = error == nil ? .pending : .failed
        case let code? where code < 300: self = .success
        case let code? where code < 400: self = .redirect
        case let code? where code < 500: self = .clientError
        default: self = .serverError
        }
    }

    public var title: String {
        switch self {
        case .pending: "Pending"
        case .success: "2xx Success"
        case .redirect: "3xx Redirect"
        case .clientError: "4xx Client Error"
        case .serverError: "5xx Server Error"
        case .failed: "Failed"
        }
    }
}
