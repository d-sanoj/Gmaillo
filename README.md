# MacMail

MacMail (formerly GmailBox) is a fast, native macOS email client built specifically for Gmail and Google Calendar. It abandons heavy web wrappers in favor of a sleek, performant architecture built purely with Swift, SwiftUI, and AppKit. 

Designed for speed and productivity, MacMail follows familiar standard macOS Mail paradigms while offering deep integration with the Google ecosystem.

## ✨ Features

### Native Architecture
- **100% Native UI**: Built entirely with SwiftUI and AppKit. No embedded web browsers, no Electron, no lag.
- **SQLite Caching**: Lightning-fast offline access. Emails, threads, labels, and sync states are all cached locally in a robust SQLite database.
- **Dark Mode Support**: Seamlessly adapts to your system theme with beautiful, high-contrast aesthetics and custom glassmorphism effects.

### Email Experience
- **Multi-Account Support**: Add and easily switch between multiple Google accounts from the top navigation bar.
- **Three-Column Layout**: A classic, highly productive layout featuring a collapsible Sidebar, a dense Thread List, and a spacious Reading Pane.
- **Undo Send**: Make a mistake? You have a 5-second grace period to cleanly recall any email before it hits the network.
- **Rich Text Composer**: Format emails with bold, italics, underline, lists, indents, and font colors.
- **Google Drive Integration**: Insert links to Google Drive files directly into your composer.
- **Inline Attachments**: Drag and drop images directly into the composer.
- **Custom Signatures**: Add a custom text signature and photo that automatically populates when writing new messages.

### Google Calendar Integration
- **Agenda Sidebar**: Toggle a sleek calendar panel on the right side of the screen to view your upcoming events without leaving your inbox.
- **Smart Meet Links**: Event cards automatically detect Google Meet links, offering a quick "Join Meet" button to instantly jump into video calls.

## 🚀 Setup & Installation

Because MacMail is a native client that directly interfaces with your personal Google data, you must configure a Google Cloud Project to generate OAuth credentials. This keeps your data entirely within your control.

> **Read the full setup guide here:** [GOOGLE_API_SETUP.md](GOOGLE_API_SETUP.md)

### Building the Source
To compile the application locally:
```bash
swift build
```

To build and run the macOS App bundle (complete with app icon):
```bash
./script/build_and_run.sh
```

## 🔒 Privacy & Security

MacMail is built with security as a first principle:
- **No Middlemen**: The app communicates directly with Google's API servers. There are no intermediary servers or proxy services tracking your data.
- **No Password Access**: The app uses secure OAuth 2.0. It never sees, stores, or transmits your Google password.
- **Local Storage**: All emails, calendar events, and OAuth tokens are stored locally on your hard drive in a secure SQLite database inside your user Library directory.

## 🛠 Tech Stack
- Language: Swift 5.10
- Frameworks: SwiftUI, AppKit, Foundation
- Network: URLSession
- Storage: SQLite3, JSONEncoder/JSONDecoder
- Build System: Swift Package Manager
