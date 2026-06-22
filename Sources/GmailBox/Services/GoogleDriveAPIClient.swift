import Foundation

struct DriveFile: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let mimeType: String
    let iconLink: URL?
    let webViewLink: URL?
}

struct DriveFileListResponse: Decodable {
    let files: [DriveFile]
    let nextPageToken: String?
}

final class GoogleDriveAPIClient {
    private let session: URLSession
    private let baseURL = URL(string: "https://www.googleapis.com/drive/v3")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func listFiles(accessToken: String, query: String? = nil, pageToken: String? = nil) async throws -> DriveFileListResponse {
        var urlComponents = URLComponents(url: baseURL.appending(path: "files"), resolvingAgainstBaseURL: false)!
        
        var queryItems = [
            URLQueryItem(name: "fields", value: "nextPageToken, files(id, name, mimeType, iconLink, webViewLink)"),
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "orderBy", value: "recency desc")
        ]
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: "name contains '\(query)' and trashed = false"))
        } else {
            queryItems.append(URLQueryItem(name: "q", value: "trashed = false"))
        }
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "GoogleDriveAPIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Drive API Error: \(errorText)"])
        }
        
        return try JSONDecoder().decode(DriveFileListResponse.self, from: data)
    }
}
