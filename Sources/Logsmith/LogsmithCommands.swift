import SwiftUI
import LogsmithCore

struct LogsmithCommands: Commands {
    let store: LogStore
    let server: ServerController

    var body: some Commands {
        CommandMenu("Requests") {
            Button(server.isRunning ? "Stop Server" : "Start Server") {
                Task {
                    await server.toggle()
                }
            }
            .keyboardShortcut("r")

            Button("Clear") {
                store.clear()
            }
            .keyboardShortcut("k")
            .disabled(store.logs.isEmpty)

            Divider()

            Button("Reset Filters") {
                store.filter = LogFilter()
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
            .disabled(!store.filter.isActive)
        }
    }
}
