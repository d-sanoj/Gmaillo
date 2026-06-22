import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var store: MailStore

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(store: store)
            Divider()
            HStack(spacing: 0) {
                SidebarView(store: store)
                    .frame(width: store.isSidebarCollapsed ? 60 : 220)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.isSidebarCollapsed)

                Divider()

                HSplitView {
                    ThreadListView(store: store)
                        .frame(minWidth: 200, idealWidth: 280, maxWidth: 350, maxHeight: .infinity)

                    ReadingPaneView(store: store)
                        .frame(minWidth: 300, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if store.isCalendarVisible {
                    Divider()
                    CalendarView(authService: store.oauthService, mailStore: store)
                        .frame(width: 300)
                        .transition(.move(edge: .trailing))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            if !store.hasAccounts {
                SetupEmptyStateView(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if store.showUndoBanner {
                HStack(spacing: 16) {
                    Text("Sending message...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Button("Undo") {
                        store.undoSend()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(nsColor: .systemYellow))
                    .fontWeight(.semibold)
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.85), in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                .padding(24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showUndoBanner)
            }
        }
        .sheet(isPresented: $store.showingComposer) {
            ComposerView(store: store)
        }
        .sheet(isPresented: $store.showingSettings) {
            SettingsView(store: store)
        }

        .alert("MacMail", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .task(id: store.selectedAccountId) {
            guard store.selectedAccountId != nil else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }
                await store.performBackgroundCheck()
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            Task {
                await store.performBackgroundCheck()
            }
        }
        .navigationTitle("MacMail")
    }
}

private struct SetupEmptyStateView: View {
    @ObservedObject var store: MailStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Connect GmailBox to your Gmail")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Import your Google OAuth desktop-client JSON in Settings, then sign in with Google. GmailBox never asks for your Gmail password.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 520)
            }

            HStack {
                Button("Open Settings") {
                    store.showingSettings = true
                }
                .buttonStyle(.borderedProminent)

                Button("Sign in with Google") {
                    store.signInWithGoogle()
                }
                .disabled(!store.oauthSummary.isConfigured || store.isSigningIn)
            }

            if store.isSigningIn {
                ProgressView("Finish Google sign-in in your browser...")
                    .controlSize(.small)
            }

            if !store.oauthSummary.isConfigured {
                Text("OAuth JSON is not configured yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }
}
