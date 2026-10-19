import SwiftUI
import LogsmithCore

struct ContentView: View {
    @Environment(LogStore.self) private var store
    @Environment(ServerController.self) private var server
    @State private var selection: HTTPLog.ID?
    @State private var searchText = ""
    @AppStorage("showsDetail") private var showsDetail = true
    @AppStorage("followsLatest") private var followsLatest = true

    var body: some View {
        RequestTable(selection: $selection, followsLatest: followsLatest)
            .frame(minWidth: 520)
            .inspector(isPresented: $showsDetail) {
                RequestDetailView(selection: selection)
                    .inspectorColumnWidth(min: 340, ideal: 460, max: 1000)
            }
            .navigationTitle("Logsmith")
            .searchable(text: $searchText, placement: .toolbar, prompt: "URL, method, status, trace ID")
            .task(id: searchText) {
                // Debounce typing so large lists aren't re-filtered on every keystroke.
                if !searchText.isEmpty {
                    try? await Task.sleep(for: .milliseconds(120))
                }
                store.filter.text = searchText
            }
            .onChange(of: store.filter.text) { _, text in
                if text != searchText { searchText = text }
            }
            .onChange(of: store.logs.isEmpty) { _, isEmpty in
                if isEmpty { selection = nil }
            }
            .toolbar {
                RequestToolbar(followsLatest: $followsLatest, showsDetail: $showsDetail)
            }
            .alert("Server Error", isPresented: Binding(
                get: { server.errorMessage != nil },
                set: { if !$0 { server.dismissError() } }
            )) {
                Button("OK") {
                    server.dismissError()
                }
            } message: {
                Text(server.errorMessage ?? "")
            }
    }
}
