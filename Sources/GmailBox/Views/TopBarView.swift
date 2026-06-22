import SwiftUI

struct TopBarView: View {
    @ObservedObject var store: MailStore

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    store.isSidebarCollapsed.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Toggle Sidebar")

            Spacer()

            HStack(spacing: 8) {
                if store.isSyncing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        if store.syncProgressTotal > 0 {
                            let percent = min(100, Int((Double(store.syncProgressCount) / Double(store.syncProgressTotal)) * 100))
                            Text(store.syncProgressCount > 0 ? "Downloading \(percent)%" : "Syncing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                                .animation(.default, value: percent)
                        } else {
                            Text(store.syncProgressCount > 0 ? "Downloading \(store.syncProgressCount)" : "Syncing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                                .animation(.default, value: store.syncProgressCount)
                        }
                    }
                    .padding(.trailing, 4)
                } else {
                    Button {
                        Task { await store.sync() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Sync")
                }
                
                Picker("", selection: Binding(
                    get: { store.selectedAccountId ?? "" },
                    set: { id in
                        if id == "ADD_ACCOUNT" {
                            store.signInWithGoogle()
                        } else {
                            store.switchAccount(to: id)
                        }
                    }
                )) {
                    ForEach(store.accounts) { account in
                        Text(account.email).tag(account.id)
                    }
                    Divider()
                    Text("Add Account...").tag("ADD_ACCOUNT")
                }
                .frame(width: 240)
                
                Button {
                    store.showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
