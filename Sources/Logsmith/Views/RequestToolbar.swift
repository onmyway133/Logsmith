import SwiftUI
import LogsmithCore

struct RequestToolbar: ToolbarContent {
    @Environment(LogStore.self) private var store
    @Environment(ServerController.self) private var server
    @Binding var followsLatest: Bool
    @Binding var showsDetail: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            ServerStatusView()
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                Task {
                    await server.toggle()
                }
            } label: {
                Label(server.isRunning ? "Stop Server" : "Start Server", systemImage: server.isRunning ? "stop.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .help(server.isRunning ? "Stop listening" : "Start listening")

            Button("Clear", systemImage: "trash") {
                store.clear()
            }
            .disabled(store.logs.isEmpty)
            .help("Clear all requests")
        }

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItemGroup(placement: .primaryAction) {
            FilterMenu()

            Toggle(isOn: $followsLatest) {
                Label("Follow Latest", systemImage: "arrow.down.to.line")
            }
            .help("Scroll to new requests as they arrive")
        }

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $showsDetail) {
                Label("Details", systemImage: "sidebar.trailing")
            }
            .help("Show or hide the detail pane")
        }
    }
}

private struct ServerStatusView: View {
    @Environment(LogStore.self) private var store
    @Environment(ServerController.self) private var server

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)
                .shadow(color: indicatorColor.opacity(0.6), radius: server.isRunning ? 3 : 0)
            Text(":" + String(server.port))
                .font(.callout.monospacedDigit().weight(.medium))
            Text(countText)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .fixedSize()
        .help(server.isRunning ? "Listening on \(server.endpoint)" : "Server stopped")
    }

    private var indicatorColor: Color {
        switch server.state {
        case .running: .green
        case .starting: .yellow
        case .stopped: .secondary
        case .failed: .red
        }
    }

    private var countText: String {
        let total = store.logs.count
        let visible = store.visibleLogs.count
        return visible == total ? "\(total.formatted()) requests" : "\(visible.formatted()) of \(total.formatted())"
    }
}
