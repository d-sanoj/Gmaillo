import SwiftUI
import AppKit

struct CalendarView: View {
    @StateObject private var calendarStore: CalendarStore
    @ObservedObject var mailStore: MailStore
    
    init(authService: GoogleOAuthService, mailStore: MailStore) {
        self._calendarStore = StateObject(wrappedValue: CalendarStore(authService: authService))
        self.mailStore = mailStore
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Upcoming Agenda")
                    .font(.headline)
                Spacer()
                Button {
                    if let account = mailStore.selectedAccount {
                        Task { await calendarStore.fetchEvents(for: account) }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh Calendar")
            }
            .padding()
            .background(.bar)
            
            Divider()
            
            if calendarStore.isLoading && calendarStore.upcomingEvents.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = calendarStore.errorMessage {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if calendarStore.upcomingEvents.isEmpty {
                ContentUnavailableView("No Upcoming Events", systemImage: "calendar", description: Text("You have no events scheduled for the near future."))
            } else {
                List(calendarStore.upcomingEvents) { event in
                    EventCard(event: event)
                        .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 250, maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .task(id: mailStore.selectedAccountId) {
            if let account = mailStore.selectedAccount {
                await calendarStore.fetchEvents(for: account)
            }
        }
    }
}

struct EventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if let start = event.start?.parsedDate {
                Text(start.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let start = event.start?.date {
                Text("All day: \(start)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let location = event.location, !location.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.blue)
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            if let hangout = event.hangoutLink, let url = URL(string: hangout) {
                Link(destination: url) {
                    Label("Join Meet", systemImage: "video.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
