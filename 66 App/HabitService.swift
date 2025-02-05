import Foundation
import Supabase

@MainActor
class HabitService: ObservableObject {
    static let shared = HabitService()
    private let supabase = SupabaseManager.shared
    private let defaults = UserDefaults.standard
    private let lastOpenedKey = "lastOpenedDate"
    
    @Published var habits: [Habit] = []
    @Published var error: String?
    
    init() {
        Task {
            await checkNewDay()
        }
    }
    
    private func checkNewDay() async {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let lastOpened = defaults.object(forKey: lastOpenedKey) as? Date ?? today
            
            print("📅 CHECK NEW DAY")
            print("📅 Today's date: \(today)")
            print("📅 Last opened: \(lastOpened)")
            
            if today > lastOpened {
                print("🔄 NEW DAY(S) DETECTED")
                
                // Save last opened day's progress
                print("💾 Saving progress for last opened date: \(lastOpened)")
                try await saveProgress(for: lastOpened)
                
                // Calculate and create entries for missed days
                let calendar = Calendar.current
                var currentDate = calendar.date(byAdding: .day, value: 1, to: lastOpened) ?? today
                
                while currentDate < today {
                    print("📝 Creating 0% entry for missed day: \(currentDate)")
                    try await saveProgress(for: currentDate, withCompletion: 0)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
                }
                
                print("🔄 Resetting all habits...")
                try await resetHabits()
                print("✅ Habits reset complete")
            }
            
            // Update last opened date
            defaults.set(today, forKey: lastOpenedKey)
            print("📅 Updated last opened date to: \(today)")
            
        } catch {
            print("❌ Error in checkNewDay: \(error)")
            self.error = error.localizedDescription
        }
    }
    
    // Fetch all habits for current user
    func fetchHabits() async throws {
        let query = supabase
            .from("habits")
            .select()
        
        let habits: [Habit] = try await query.execute().value
        self.habits = habits
    }
    
    // Create a new habit
    func createHabit(title: String) async throws {
        do {
            let userId = try await supabase.auth.session.user.id
            print("Got user ID: \(userId)")
            
            let habit = Habit(
                id: UUID(),
                userId: userId,
                title: title,
                isCompleted: false,
                createdAt: Date()
            )
            print("Created habit object: \(habit)")
            
            try await supabase
                .from("habits")
                .insert(habit)
                .execute()
            print("Successfully inserted habit")
            
            try await fetchHabits()
        } catch {
            print("Error creating habit: \(error)")
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // Update habit completion status
    func updateHabit(id: UUID, isCompleted: Bool) async throws {
        try await supabase
            .from("habits")
            .update(["is_completed": isCompleted])
            .eq("id", value: id)
            .execute()
        
        // Update local state
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].isCompleted = isCompleted
        }
    }
    
    // Delete a habit
    func deleteHabit(id: UUID) async throws {
        try await supabase
            .from("habits")
            .delete()
            .eq("id", value: id)
            .execute()
        
        // Update local state
        habits.removeAll { $0.id == id }
    }
    
    var completionPercentage: Double {
        guard !habits.isEmpty else { return 0 }
        let completedCount = habits.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(habits.count)
    }
    
    var completedCount: Int {
        habits.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        habits.count
    }
    
    // Add these methods to HabitService class
    func saveCompletionHistory(for date: Date? = nil) async throws {
        let userId = try await supabase.auth.session.user.id
        let dateToUse = date ?? Calendar.current.startOfDay(for: Date())
        
        let history = CompletionHistory(
            id: UUID(),
            userId: userId,
            date: dateToUse,
            completionPercentage: completionPercentage,
            createdAt: Date()
        )
        
        try await supabase
            .from("completion_history")
            .insert(history)
            .execute()
    }
    
    func getCompletionHistory(for date: Date) async throws -> CompletionHistory? {
        let userId = try await supabase.auth.session.user.id
        
        let histories: [CompletionHistory] = try await supabase
            .from("completion_history")
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: date)
            .execute()
            .value
        
        return histories.first
    }
    
    private func saveProgress(for date: Date, withCompletion completion: Double? = nil) async throws {
        if completion == nil {
            print("💾 Preparing to save progress for: \(date)")
            // Fetch latest habit state before saving
            print("📥 Fetching current habit state...")
            try await fetchHabits()
        }
        
        let userId = try await supabase.auth.session.user.id
        
        let history = CompletionHistory(
            id: UUID(),
            userId: userId,
            date: date,
            completionPercentage: completion ?? completionPercentage,
            createdAt: Date()
        )
        
        print("💾 Saving progress:")
        print("📅 Date: \(date)")
        print("📊 Completion: \(completion ?? completionPercentage * 100)%")
        
        try await supabase
            .from("completion_history")
            .insert(history)
            .execute()
        
        print("✅ Progress saved successfully")
    }
    
    private func resetHabits() async throws {
        print("🔄 Starting habit reset")
        print("📊 Before reset - Completed: \(completedCount)/\(totalCount)")
        
        // Reset all habits to incomplete
        for habit in habits {
            try await updateHabit(id: habit.id, isCompleted: false)
        }
        
        // Refresh habits list
        try await fetchHabits()
        
        print("✅ After reset - Completed: \(completedCount)/\(totalCount)")
    }
    
    func getMonthCompletionHistory(for date: Date) async throws -> [CompletionHistory] {
        let calendar = Calendar.current
        let userId = try await supabase.auth.session.user.id
        
        // Get start and end of month
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        
        print("📊 Fetching completion history")
        print("📅 From: \(monthInterval.start)")
        print("📅 To: \(monthInterval.end)")
        
        let histories: [CompletionHistory] = try await supabase
            .from("completion_history")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: monthInterval.start)  // Greater than or equal to start
            .lt("date", value: monthInterval.end)     // Less than end
            .execute()
            .value
        
        print("📊 Found \(histories.count) history entries")
        return histories
    }
} 