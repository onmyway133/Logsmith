import SwiftUI
import LogsmithCore

@main
struct LogsmithApp: App {
    @State private var store: LogStore
    @State private var server: ServerController

    init() {
        let store = LogStore()
        let port = UserDefaults.standard.integer(forKey: "serverPort")
        _store = State(initialValue: store)
        _server = State(initialValue: ServerController(port: port > 0 ? port : ServerController.defaultPort) { [weak store] entries in
            store?.ingest(entries)
        })
    }

    var body: some Scene {
        Window("Logsmith", id: "main") {
            ContentView()
                .environment(store)
                .environment(server)
                .task {
                    await server.start()
                }
        }
        .defaultSize(width: 1300, height: 800)
        .commands {
            LogsmithCommands(store: store, server: server)
            InspectorCommands()
        }

        Settings {
            SettingsView()
                .environment(server)
        }
    }
}
