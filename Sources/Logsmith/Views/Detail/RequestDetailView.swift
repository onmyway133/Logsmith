import SwiftUI
import LogsmithCore

struct RequestDetailView: View {
    @Environment(LogStore.self) private var store
    let selection: HTTPLog.ID?

    var body: some View {
        if let log = store.log(id: selection) {
            LogDetailView(log: log)
        } else {
            ContentUnavailableView("No Request Selected", systemImage: "network", description: Text("Select a request to inspect its headers and body."))
        }
    }
}

private struct LogDetailView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case request = "Request"
        case response = "Response"
        var id: Self { self }
    }

    let log: HTTPLog
    @AppStorage("detailTab") private var tab = Tab.response

    var body: some View {
        VStack(spacing: 12) {
            SummaryCard(log: log)
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            switch (tab, log.statusClass) {
            case (.request, _):
                MessageView(id: "\(log.id)-request", headers: log.requestHeaders, content: log.requestBody)
            case (.response, .pending):
                ContentUnavailableView {
                    ProgressView()
                } description: {
                    Text("Waiting for response…")
                }
            case (.response, .failed):
                ContentUnavailableView("Request Failed", systemImage: "xmark.octagon", description: Text(log.error ?? ""))
            case (.response, _):
                MessageView(id: "\(log.id)-response-\(log.revision)", headers: log.responseHeaders ?? [:], content: log.responseBody)
            }
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct SummaryCard: View {
    let log: HTTPLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Pill(text: log.method, color: .method(log.method))
                Pill(text: statusText, color: .status(log.statusClass))
                Spacer(minLength: 0)
                Menu {
                    LogActions(log: log)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .menuIndicator(.hidden)
                .buttonStyle(.glass)
                .help("Copy")
            }
            Text(log.url)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
            HStack(spacing: 14) {
                Metric(systemImage: "clock", text: log.date.formatted(date: .omitted, time: .standard))
                Metric(systemImage: "timer", text: log.durationText)
                Metric(systemImage: "arrow.down.circle", text: log.sizeText)
                Spacer(minLength: 0)
            }
            Text(log.id)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var statusText: String {
        switch log.statusClass {
        case .pending: "Pending"
        case .failed: "Failed"
        default: log.statusCode.map { "\($0) \(HTTPURLResponse.localizedString(forStatusCode: $0).capitalized)" } ?? ""
        }
    }
}

private struct Pill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.callout.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(color.opacity(0.25)), in: .capsule)
    }
}

private struct Metric: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.callout.monospacedDigit())
            .foregroundStyle(.secondary)
    }
}
