import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    Task {
                        try? await authManager.signOut()
                    }
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
} 