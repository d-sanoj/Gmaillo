import Foundation

final class GoogleCalendarAPIClient {
    private let authService: GoogleOAuthService
    private let session: URLSession
    private let baseURL = "https://www.googleapis.com/calendar/v3"

    init(authService: GoogleOAuthService, session: URLSession = .shared) {
        self.authService = authService
        self.session = session
    }

    func fetchUpcomingEvents(for account: GmailAccount) async throws -> [CalendarEvent] {
        let token = try await authService.validAccessToken(for: account)
        
        let now = ISO8601DateFormatter().string(from: Date())
        var components = URLComponents(string: "\(baseURL)/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: now),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown"
            print("Calendar API Error: \(httpResponse.statusCode) - \(errorString)")
            
            var msg = "API Error \(httpResponse.statusCode): \(errorString)"
            if httpResponse.statusCode == 403 {
                if errorString.contains("not been used in project") || errorString.contains("disabled") {
                    msg = "Google Calendar API is NOT enabled in your Google Cloud Project. Please go to your Google Cloud Console, search for 'Google Calendar API', and click Enable. Then try again."
                } else {
                    msg = "Permission denied. If you just enabled the API, wait a few minutes. Otherwise, please Remove Account in Settings and sign in again to grant Calendar access. (Error: \(errorString))"
                }
            }
            throw NSError(domain: "CalendarAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(CalendarEventListResponse.self, from: data)
        return result.items
    }
}
