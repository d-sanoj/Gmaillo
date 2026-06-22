import SwiftUI

struct TestView: View {
    var body: some View {
        HStack(spacing: 0) {
            Button {
            } label: {
                Text("Send")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider().frame(height: 26).background(Color.white.opacity(0.3))
            
            Menu {
                Button("Schedule Send") { }
            } label: {
                Image(systemName: "chevron.down")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
        }
        .background(Color.accentColor)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
