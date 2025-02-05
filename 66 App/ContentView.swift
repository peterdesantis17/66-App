//
//  ContentView.swift
//  66 App
//
//  Created by Peter on 2025-02-02.
//

import SwiftUI

struct Habit: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case isCompleted = "is_completed"
        case createdAt = "created_at"
    }
}

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    HabitsView()
                        .tabItem {
                            Label("Habits", systemImage: "list.bullet")
                        }
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            } else {
                LoginView()
            }
        }
    }
}

struct AddHabitView: View {
    @StateObject private var habitService = HabitService.shared
    @Binding var isPresented: Bool
    @State private var newHabitTitle = ""
    @State private var showError = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    TextField("Habit Title", text: $newHabitTitle)
                    
                    Button("Add Habit") {
                        addHabit()
                    }
                    .disabled(newHabitTitle.isEmpty || isLoading)
                }
                .navigationTitle("New Habit")
                .navigationBarItems(trailing: Button("Cancel") {
                    isPresented = false
                })
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(habitService.error ?? "An error occurred")
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
    
    private func addHabit() {
        Task {
            isLoading = true
            do {
                try await habitService.createHabit(title: newHabitTitle)
                isPresented = false
            } catch {
                print("AddHabitView error: \(error)")
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
