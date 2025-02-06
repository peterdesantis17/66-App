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
            print("📅 Raw current date: \(Date())")
            
            if today > lastOpened {
                print("🔄 NEW DAY(S) DETECTED - Refreshing session")
                // Force a new session when date changes
                try await supabase.auth.refreshSession()
                
                print("🔄 NEW DAY(S) DETECTED")
                print("📅 Days difference: \(Calendar.current.dateComponents([.day], from: lastOpened, to: today).day ?? 0)")
                
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
            print("❌ CheckNewDay error: \(error)")
            print("❌ Error type: \(type(of: error))")
            self.error = error.localizedDescription
        }
    }
    
    // Fetch all habits for current user
    func fetchHabits() async throws {
        let fetchStartTime = Date()
        print("📱 HabitService: Fetching habits at \(fetchStartTime)")
        do {
            print("🔐 HabitService: Getting session...")
            let supabaseClient = supabase // Get reference to avoid multiple accesses
            print("🔧 HabitService: Using Supabase client")
            let session = try await supabaseClient.auth.session
            let userId = session.user.id
            print("✅ HabitService: Got session for user \(userId)")
            print("🔐 HabitService: Token - \(session.accessToken.prefix(20))...")
            
            let query = supabaseClient  // Use same client instance
                .from("habits")
                .select()
                .eq("user_id", value: userId)
            
            print("🔄 HabitService: Executing query...")
            let queryStartTime = Date()
            let response: PostgrestResponse<[Habit]> = try await query.execute()
            let queryDuration = Date().timeIntervalSince(queryStartTime)
            print("📥 HabitService: Response received after \(String(format: "%.2f", queryDuration))s")
            print("📥 HabitService: Response status - \(response.status)")
            
            if response.status == 200 {
                let habits = try response.value
                print("📱 HabitService: Decoded \(habits.count) habits")
                if habits.isEmpty {
                    print("⚠️ HabitService: Warning - Got 0 habits despite successful response")
                }
                self.habits = habits
            } else {
                print("❌ HabitService: Unexpected status code: \(response.status)")
                throw NSError(domain: "HabitService", code: response.status, userInfo: nil)
            }
            
            let totalDuration = Date().timeIntervalSince(fetchStartTime)
            print("⏱️ HabitService: Total fetch duration: \(String(format: "%.2f", totalDuration))s")
        } catch {
            print("❌ HabitService: Fetch error - \(error)")
            print("❌ HabitService: Error type - \(type(of: error))")
            print("❌ HabitService: Full error details - \(String(describing: error))")
            throw error
        }
    }
    
    // Create a new habit
    func createHabit(title: String) async throws {
        print("📱 HabitService: Creating new habit - '\(title)'")
        do {
            let session = try await supabase.auth.session
            print("🔐 HabitService: Session state - \(session.accessToken)")
            print("👤 HabitService: User ID - \(session.user.id)")
            
            let userId = session.user.id
            print("👤 HabitService: User ID - \(userId)")
            
            let habit = Habit(
                id: UUID(),
                userId: userId,
                title: title,
                isCompleted: false,
                createdAt: Date()
            )
            
            try await supabase
                .from("habits")
                .insert(habit)
                .execute()
            print("✅ HabitService: Habit created successfully")
            
            try await fetchHabits()
        } catch {
            print("❌ HabitService: Create error - \(error)")
            print("❌ HabitService: Error type - \(type(of: error))")
            print("❌ HabitService: Full error details - \(String(describing: error))")
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
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        
        let histories: [CompletionHistory] = try await supabase
            .from("completion_history")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: monthInterval.start)
            .lt("date", value: monthInterval.end)
            .execute()
            .value
        
        return histories
    }
} 