import SwiftUI

struct HabitsView: View {
    @StateObject private var habitService = HabitService.shared
    @State private var showingAddHabit = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var requestId = 0  // Add this to track requests
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    ProgressRingView(progress: habitService.completionPercentage)
                        .padding(.vertical)
                    
                    List {
                        ForEach(habitService.habits) { habit in
                            HStack {
                                Text(habit.title)
                                Spacer()
                                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(habit.isCompleted ? .green : .gray)
                                    .onTapGesture {
                                        Task {
                                            do {
                                                try await habitService.updateHabit(id: habit.id, isCompleted: !habit.isCompleted)
                                            } catch {
                                                showError = true
                                            }
                                        }
                                    }
                            }
                        }
                        .onDelete { indexSet in
                            deleteHabits(at: indexSet)
                        }
                    }
                    .refreshable {
                        await loadHabits(requestId: requestId)
                    }
                    
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Habit")
                        }
                        .padding()
                    }
                }
                .navigationTitle("My Habits")
                .sheet(isPresented: $showingAddHabit) {
                    AddHabitView(isPresented: $showingAddHabit)
                }
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
        .task {
            let currentRequest = requestId
            print("🔄 HabitsView[\(currentRequest)]: Task started")
            await loadHabits(requestId: currentRequest)
        }
        .onAppear {
            print("👀 HabitsView: onAppear")
            requestId += 1  // Increment request ID
        }
        .onDisappear {
            print("👻 HabitsView: onDisappear")
        }
    }
    
    private func loadHabits(requestId: Int) async {
        print("📱 HabitsView[\(requestId)]: Starting load")
        isLoading = true
        do {
            print("⏳ HabitsView[\(requestId)]: Before fetch")
            try await habitService.fetchHabits()
            if requestId == self.requestId {  // Only update if this is the latest request
                print("✅ HabitsView[\(requestId)]: Load completed successfully")
            } else {
                print("⚠️ HabitsView[\(requestId)]: Load completed but request is stale")
            }
        } catch {
            print("❌ HabitsView[\(requestId)]: Load error - \(error)")
            if requestId == self.requestId {
                showError = true
            } else {
                print("⚠️ HabitsView[\(requestId)]: Error ignored as request is stale")
            }
        }
        isLoading = false
    }
    
    private func deleteHabits(at indexSet: IndexSet) {
        Task {
            do {
                for index in indexSet {
                    let habit = habitService.habits[index]
                    try await habitService.deleteHabit(id: habit.id)
                }
            } catch {
                showError = true
            }
        }
    }
} 