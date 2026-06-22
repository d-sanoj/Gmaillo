import SwiftUI

struct DrivePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MailStore
    let onSelect: (DriveFile) -> Void
    
    @State private var files: [DriveFile] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String? = nil
    
    private let driveClient = GoogleDriveAPIClient()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Insert from Google Drive")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Drive", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await fetchFiles() }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await fetchFiles() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView("Error Loading Drive", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if files.isEmpty {
                ContentUnavailableView("No files found", systemImage: "folder", description: Text("Try a different search term."))
            } else {
                List(files) { file in
                    Button {
                        onSelect(file)
                        dismiss()
                    } label: {
                        HStack {
                            if let iconURL = file.iconLink {
                                AsyncImage(url: iconURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "doc")
                                }
                                .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "doc")
                            }
                            
                            Text(file.name)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 500, height: 600)
        .task {
            await fetchFiles()
        }
    }
    
    private func fetchFiles() async {
        guard let account = store.selectedAccount else {
            errorMessage = "No active account"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let token = try await store.oauthService.validAccessToken(for: account)
            let response = try await driveClient.listFiles(accessToken: token, query: searchText)
            await MainActor.run {
                self.files = response.files
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
