import SwiftUI
import LogsmithCore

struct MessageView: View {
    let id: String
    let headers: [String: String]
    let content: String?
    @AppStorage("headersExpanded") private var headersExpanded = true
    @AppStorage("prettyPrintBody") private var prettyPrint = true
    @State private var rendered: RenderedBody?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $headersExpanded) {
                HeadersView(headers: headers)
                    .padding(.top, 6)
            } label: {
                SectionTitle(title: "Headers", detail: "\(headers.count)")
            }
            Divider()
            bodyHeader
            if let content, !content.isEmpty {
                BodyTextView(rendered: rendered)
                    .overlay {
                        if rendered == nil {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
            } else {
                Text("No body")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .task(id: "\(id)-\(prettyPrint)") {
            rendered = nil
            guard let content, !content.isEmpty else { return }
            let prettyPrint = prettyPrint
            rendered = await Task.detached(priority: .userInitiated) {
                RenderedBody(content, prettyPrint: prettyPrint)
            }.value
        }
    }

    private var bodyHeader: some View {
        HStack {
            SectionTitle(title: "Body", detail: (content?.utf8.count ?? 0).formatted(.byteCount(style: .file)))
            Spacer()
            if rendered?.isJSON == true {
                Toggle("Pretty", isOn: $prettyPrint)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
            Button("Copy Body", systemImage: "doc.on.doc") {
                Pasteboard.copy(rendered?.text ?? content ?? "")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .disabled(content?.isEmpty ?? true)
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(.quaternary, in: .capsule)
        }
    }
}

private struct HeadersView: View {
    let headers: [String: String]

    var body: some View {
        if headers.isEmpty {
            Text("No headers")
                .font(.callout)
                .foregroundStyle(.tertiary)
        } else {
            ScrollView {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 5) {
                    ForEach(headers.sorted { $0.key.lowercased() < $1.key.lowercased() }, id: \.key) { name, value in
                        GridRow {
                            Text(name)
                                .foregroundStyle(.secondary)
                                .gridColumnAlignment(.trailing)
                            Text(value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contextMenu {
                            Button("Copy Value") {
                                Pasteboard.copy(value)
                            }
                            Button("Copy Header") {
                                Pasteboard.copy("\(name): \(value)")
                            }
                        }
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            }
            .frame(maxHeight: 220)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
