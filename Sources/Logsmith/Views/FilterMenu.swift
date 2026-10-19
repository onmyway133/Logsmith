import SwiftUI
import LogsmithCore

struct FilterMenu: View {
    @Environment(LogStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Menu {
            Section("Status") {
                ForEach(StatusClass.allCases) { statusClass in
                    Toggle(statusClass.title, isOn: membership(\.statusClasses, statusClass))
                }
            }
            if !store.methods.isEmpty {
                Section("Method") {
                    ForEach(store.methods, id: \.self) { method in
                        Toggle(method, isOn: membership(\.methods, method))
                    }
                }
            }
            if !store.hosts.isEmpty {
                Menu("Host") {
                    ForEach(store.hosts, id: \.self) { host in
                        Toggle(host, isOn: membership(\.hosts, host))
                    }
                }
            }
            Section {
                Toggle("Search in Bodies", isOn: $store.filter.includeBodies)
                Button("Reset Filters") {
                    store.filter = LogFilter(text: store.filter.text)
                }
                .disabled(!store.filter.hasMenuFilters)
            }
        } label: {
            Label("Filter", systemImage: store.filter.hasMenuFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .menuIndicator(.hidden)
        .help("Filter by status, method, and host")
    }

    private func membership<Value: Hashable>(_ keyPath: WritableKeyPath<LogFilter, Set<Value>>, _ value: Value) -> Binding<Bool> {
        Binding {
            store.filter[keyPath: keyPath].contains(value)
        } set: { isOn in
            if isOn {
                store.filter[keyPath: keyPath].insert(value)
            } else {
                store.filter[keyPath: keyPath].remove(value)
            }
        }
    }
}
