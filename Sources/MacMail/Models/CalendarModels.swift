import Foundation

struct CalendarEventListResponse: Decodable {
    let items: [CalendarEvent]
}

struct CalendarEvent: Decodable, Identifiable {
    let id: String
    let summary: String?
    let description: String?
    let location: String?
    let start: EventDateTime?
    let end: EventDateTime?
    let hangoutLink: String?
    let htmlLink: String?
    let creator: EventCreator?
    
    var title: String {
        summary ?? "No Title"
    }
}

struct EventDateTime: Decodable {
    let date: String?
    let dateTime: String?
    let timeZone: String?
    
    var parsedDate: Date? {
        if let dateTime = dateTime {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = formatter.date(from: dateTime) { return d }
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateTime)
        } else if let dateStr = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: timeZone ?? "UTC") ?? TimeZone.current
            return formatter.date(from: dateStr)
        }
        return nil
    }
}

struct EventCreator: Decodable {
    let email: String?
    let displayName: String?
}
