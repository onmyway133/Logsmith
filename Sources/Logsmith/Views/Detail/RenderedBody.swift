import Foundation

struct RenderedBody: Sendable, Equatable {
    enum Token: Sendable, Equatable {
        case key, string, number, literal
    }

    let text: String
    let isJSON: Bool
    let highlights: [(NSRange, Token)]

    static func == (lhs: RenderedBody, rhs: RenderedBody) -> Bool {
        lhs.text == rhs.text && lhs.isJSON == rhs.isJSON
    }

    // Regex highlighting gets slow on multi-megabyte bodies, so skip it past this size.
    private static let highlightLimit = 400_000
    private static let pattern = try? NSRegularExpression(pattern: #"("(?:[^"\\]|\\.)*")(\s*:)?|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|\b(true|false|null)\b"#)

    init(_ raw: String, prettyPrint: Bool) {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              !(object is String) || raw.hasPrefix("\"")
        else {
            text = raw
            isJSON = false
            highlights = []
            return
        }
        isJSON = true
        if prettyPrint,
           let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]),
           let string = String(data: pretty, encoding: .utf8) {
            text = string
        } else {
            text = raw
        }
        highlights = text.utf16.count <= Self.highlightLimit ? Self.highlight(text) : []
    }

    private static func highlight(_ text: String) -> [(NSRange, Token)] {
        guard let pattern else { return [] }
        return pattern.matches(in: text, range: NSRange(location: 0, length: text.utf16.count)).compactMap { match in
            if match.range(at: 1).location != NSNotFound {
                return (match.range(at: 1), match.range(at: 2).location != NSNotFound ? .key : .string)
            }
            if match.range(at: 3).location != NSNotFound { return (match.range(at: 3), .number) }
            if match.range(at: 4).location != NSNotFound { return (match.range(at: 4), .literal) }
            return nil
        }
    }
}
