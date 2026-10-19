import AppKit
import SwiftUI
import LogsmithCore

extension Color {
    static func method(_ method: String) -> Color {
        switch method {
        case "GET": .blue
        case "POST": .green
        case "PUT": .orange
        case "PATCH": .purple
        case "DELETE": .red
        default: .secondary
        }
    }

    static func status(_ statusClass: StatusClass) -> Color {
        switch statusClass {
        case .pending: .secondary
        case .success: .green
        case .redirect: .teal
        case .clientError: .orange
        case .serverError, .failed: .red
        }
    }
}

extension HTTPLog {
    static let timeFormat = Date.FormatStyle.dateTime
        .hour(.twoDigits(amPM: .omitted))
        .minute(.twoDigits)
        .second(.twoDigits)
        .secondFraction(.fractional(3))

    var isSlow: Bool { (elapsedMs ?? 0) > 1000 }

    var durationText: String {
        guard let elapsedMs else { return "-" }
        return elapsedMs < 1000 ? "\(Int(elapsedMs.rounded())) ms" : String(format: "%.2f s", elapsedMs / 1000)
    }

    var sizeText: String {
        responseBody == nil ? "-" : responseSize.formatted(.byteCount(style: .file))
    }
}

enum Pasteboard {
    static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
