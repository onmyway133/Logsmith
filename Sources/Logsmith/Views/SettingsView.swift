import SwiftUI
import LogsmithCore

struct SettingsView: View {
    @Environment(ServerController.self) private var server
    @AppStorage("serverPort") private var storedPort = ServerController.defaultPort
    @State private var port = ServerController.defaultPort

    private var isValid: Bool { (1024...65535).contains(port) }

    var body: some View {
        Form {
            Section {
                LabeledContent("Port") {
                    TextField("Port", value: $port, format: .number.grouping(.never))
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .onSubmit(apply)
                }
                LabeledContent("Endpoint") {
                    Text(verbatim: "http://127.0.0.1:\(port)/log")
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } header: {
                Text("Server")
            } footer: {
                HStack {
                    if !isValid {
                        Text("Use a port between 1024 and 65535.")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Button("Apply & Restart", action: apply)
                        .buttonStyle(.glassProminent)
                        .disabled(!isValid || (port == server.port && server.isRunning))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize()
        .onAppear {
            port = storedPort
        }
    }

    private func apply() {
        guard isValid else { return }
        storedPort = port
        Task {
            await server.restart(port: port)
        }
    }
}
