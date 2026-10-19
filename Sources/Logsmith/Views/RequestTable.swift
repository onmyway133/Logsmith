import SwiftUI
import LogsmithCore

struct RequestTable: View {
    @Environment(LogStore.self) private var store
    @Binding var selection: HTTPLog.ID?
    let followsLatest: Bool

    var body: some View {
        @Bindable var store = store
        ScrollViewReader { proxy in
            Table(store.visibleLogs, selection: $selection, sortOrder: $store.sortOrder) {
                TableColumn("#", value: \.sequence) { log in
                    Text(log.sequence + 1, format: .number.grouping(.never))
                        .foregroundStyle(.tertiary)
                }
                .width(min: 32, ideal: 44, max: 72)
                TableColumn("Time", value: \.date) { log in
                    Text(log.date, format: HTTPLog.timeFormat)
                        .foregroundStyle(.secondary)
                }
                .width(min: 96, ideal: 104, max: 140)
                TableColumn("Method", value: \.method) { log in
                    Text(log.method)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.method(log.method))
                }
                .width(min: 50, ideal: 64, max: 90)
                TableColumn("Status", value: \.statusSortKey) { log in
                    StatusCell(log: log)
                }
                .width(min: 54, ideal: 60, max: 80)
                TableColumn("Host", value: \.host) { log in
                    Text(log.host)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .width(min: 80, ideal: 160)
                TableColumn("Path", value: \.path) { log in
                    Text(log.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(log.url)
                }
                .width(min: 160, ideal: 360)
                TableColumn("Duration", value: \.elapsedSortKey) { log in
                    Text(log.durationText)
                        .foregroundStyle(log.isSlow ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 76, ideal: 84, max: 110)
                TableColumn("Size", value: \.responseSize) { log in
                    Text(log.sizeText)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 76, ideal: 84, max: 110)
            }
            .font(.system(.callout, design: .monospaced))
            .monospacedDigit()
            .tableStyle(.inset)
            .alternatingRowBackgrounds(.enabled)
            .contextMenu(forSelectionType: HTTPLog.ID.self) { ids in
                if let log = store.log(id: ids.first) {
                    LogActions(log: log)
                }
            }
            .onChange(of: store.visibleLogs.last?.id) { _, id in
                guard followsLatest, let id, store.sortOrder == LogStore.defaultSortOrder else { return }
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
        .overlay {
            if store.visibleLogs.isEmpty {
                EmptyRequestsView()
            }
        }
    }
}

private struct StatusCell: View {
    let log: HTTPLog

    var body: some View {
        switch log.statusClass {
        case .pending:
            Image(systemName: "ellipsis")
                .foregroundStyle(.tertiary)
                .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
        case .failed:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(Color.status(.failed))
                .help(log.error ?? "")
        default:
            Text(log.statusCode ?? 0, format: .number.grouping(.never))
                .fontWeight(.semibold)
                .foregroundStyle(Color.status(log.statusClass))
        }
    }
}

struct LogActions: View {
    let log: HTTPLog

    var body: some View {
        Button("Copy URL", systemImage: "link") {
            Pasteboard.copy(log.url)
        }
        Button("Copy as cURL", systemImage: "terminal") {
            Pasteboard.copy(log.curlCommand)
        }
        Button("Copy Trace ID", systemImage: "number") {
            Pasteboard.copy(log.id)
        }
        if let body = log.responseBody, !body.isEmpty {
            Divider()
            Button("Copy Response Body", systemImage: "doc.on.doc") {
                Pasteboard.copy(body)
            }
        }
    }
}

private struct EmptyRequestsView: View {
    @Environment(LogStore.self) private var store
    @Environment(ServerController.self) private var server

    var body: some View {
        if !store.logs.isEmpty {
            ContentUnavailableView.search(text: store.filter.text)
        } else if server.isRunning {
            ContentUnavailableView {
                Label("Waiting for Requests", systemImage: "antenna.radiowaves.left.and.right")
                    .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
            } description: {
                Text("Send logs to \(server.endpoint)")
                    .textSelection(.enabled)
            }
        } else {
            ContentUnavailableView {
                Label("Server Stopped", systemImage: "pause.circle")
            } description: {
                Text("Start the server to capture requests.")
            } actions: {
                Button("Start Server") {
                    Task {
                        await server.start()
                    }
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}
