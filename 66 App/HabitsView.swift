import SwiftUI

struct HabitsView: View {
    @StateObject private var habitService = HabitService.shared
    @State private var showingAddHabit = false
    @State private var isLoading = false
    @State private var showError = false
    
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
                        await loadHabits()
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
            await loadHabits()
        }
    }
    
    private func loadHabits() async {
        isLoading = true
        do {
            try await habitService.fetchHabits()
        } catch {
            showError = true
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