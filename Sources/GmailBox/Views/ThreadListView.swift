import SwiftUI

struct ThreadListView: View {
    @ObservedObject var store: MailStore
    @AppStorage("CollapsedTimeSections") private var collapsedSectionsRaw: String = ""
    
    private var collapsedSections: Set<String> {
        get { Set(collapsedSectionsRaw.split(separator: ",").map(String.init)) }
        set { collapsedSectionsRaw = newValue.joined(separator: ",") }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search mail", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await store.refresh() }
                    }
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isInboxOrCategory {
                Divider()
                CategoryTabsView(store: store)
            }

            Divider()

            if store.filteredThreads.isEmpty {
                ContentUnavailableView(
                    "No mail here",
                    systemImage: "tray",
                    description: Text("Try another label or search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: Binding(
                    get: { store.selectedThreadIds },
                    set: { ids in
                        store.selectedThreadIds = ids
                        if ids.count == 1, let id = ids.first {
                            store.selectThread(id: id)
                        }
                    }
                )) {
                    ForEach(groupedThreads, id: \.0) { section, threads in
                        ThreadSection(
                            section: section,
                            threads: threads,
                            store: store,
                            collapsedSections: Binding(
                                get: { Set(collapsedSectionsRaw.split(separator: ",").map(String.init)) },
                                set: { collapsedSectionsRaw = $0.joined(separator: ",") }
                            )
                        )
                    }
                }
                .listStyle(.inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear.contentShape(Rectangle()).onTapGesture {
                    store.selectedThreadIds.removeAll()
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var isInboxOrCategory: Bool {
        switch store.selectedMailbox {
        case .system(let id) where id == GmailSystemLabel.inbox:
            return true
        case .category:
            return true
        default:
            return false
        }
    }

    private var groupedThreads: [(TimeSection, [GmailThread])] {
        var groups: [TimeSection: [GmailThread]] = [:]
        for thread in store.filteredThreads {
            let section = thread.lastMessageDate.timeSection
            groups[section, default: []].append(thread)
        }
        return TimeSection.allCases.compactMap { section in
            guard let threads = groups[section], !threads.isEmpty else { return nil }
            return (section, threads)
        }
    }
}

private struct ListRow: View {
    let thread: GmailThread
    @ObservedObject var store: MailStore

    var body: some View {
        ThreadRowView(
            thread: thread,
            labels: store.labels.filter { thread.labelIds.contains($0.id) && $0.type == .user },
            trashAction: { store.trashThread(thread) }
        )
        .contextMenu {
            if !store.isTrashFolder {
                Button("Archive") { store.archiveSelectedThreads() }
            }
            Button("Toggle Read/Unread") { store.toggleUnreadSelectedThreads() }
            if !store.isTrashFolder {
                Button("Trash", role: .destructive) { store.trashSelectedThreads() }
            }
        }
    }
}

private struct ThreadSection: View {
    let section: TimeSection
    let threads: [GmailThread]
    @ObservedObject var store: MailStore
    @Binding var collapsedSections: Set<String>

    var body: some View {
        Section(header: SectionHeaderView(section: section, collapsedSections: $collapsedSections)) {
            if !collapsedSections.contains(section.rawValue) {
                ForEach(threads) { thread in
                    ListRow(thread: thread, store: store)
                        .tag(thread.id)
                }
            }
        }
    }
}

private struct SectionHeaderView: View {
    let section: TimeSection
    @Binding var collapsedSections: Set<String>

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if collapsedSections.contains(section.rawValue) {
                    collapsedSections.remove(section.rawValue)
                } else {
                    collapsedSections.insert(section.rawValue)
                }
            }
        } label: {
            HStack {
                Text(section.rawValue).font(.subheadline.bold())
                Spacer()
                Image(systemName: collapsedSections.contains(section.rawValue) ? "chevron.right" : "chevron.down")
                    .font(.caption.bold())
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

private struct CategoryTabsView: View {
    @ObservedObject var store: MailStore

    private let tabs: [(title: String, icon: String, selection: MailboxSelection)] = [
        ("Primary", "tray.fill", .category(GmailCategoryLabel.primary)),
        ("Promotions", "tag", .category(GmailCategoryLabel.promotions)),
        ("Social", "person.2", .category(GmailCategoryLabel.social))
    ]

    var body: some View {
        HStack {
            Menu {
                ForEach(tabs, id: \.title) { tab in
                    Button {
                        store.selectMailbox(tab.selection)
                    } label: {
                        Label(tab.title, systemImage: tab.icon)
                    }
                }
            } label: {
                let current = tabs.first(where: { $0.selection == store.selectedMailbox }) ?? tabs[0]
                HStack(spacing: 6) {
                    Image(systemName: current.icon)
                    Text(current.title)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

private struct ThreadRowView: View {
    let thread: GmailThread
    let labels: [GmailLabel]
    let trashAction: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .opacity(thread.isUnread ? 1 : 0)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(thread.senderDisplay)
                        .fontWeight(thread.isUnread ? .semibold : .regular)
                        .lineLimit(1)
                    Spacer()
                    ZStack(alignment: .trailing) {
                        if thread.hasAttachments {
                            Image(systemName: "paperclip")
                                .foregroundStyle(.secondary)
                                .opacity(isHovering ? 0 : 1)
                        }
                        
                        Button(action: trashAction) {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                        .help("Delete")
                        .opacity(isHovering ? 1 : 0)
                    }
                    Text(thread.lastMessageDate.mailboxTimestamp)
                        .font(.caption)
                        .foregroundStyle(thread.isUnread ? .primary : .secondary)
                }

                Text(thread.subject)
                    .font(.subheadline)
                    .fontWeight(thread.isUnread ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !thread.snippet.isEmpty {
                    Text(thread.snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(labels) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((Color(hex: label.colorHex) ?? .secondary).opacity(0.18), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
