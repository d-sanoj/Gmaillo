import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let calendarClient: GoogleCalendarAPIClient
    
    init(authService: GoogleOAuthService) {
        self.calendarClient = GoogleCalendarAPIClient(authService: authService)
    }
    
    func fetchEvents(for account: GmailAccount) async {
        isLoading = true
        errorMessage = nil
        do {
            upcomingEvents = try await calendarClient.fetchUpcomingEvents(for: account)
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
