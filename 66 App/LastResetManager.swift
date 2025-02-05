import Foundation

class LastResetManager {
    static let shared = LastResetManager()
    private let defaults = UserDefaults.standard
    private let lastResetKeyPrefix = "lastResetDate"
    
    private func getKey(for userId: String) -> String {
        return "\(lastResetKeyPrefix)_\(userId)"
    }
    
    func getLastResetDate(for userId: String) -> Date? {
        return defaults.object(forKey: getKey(for: userId)) as? Date
    }
    
    func setLastResetDate(_ date: Date, for userId: String) {
        defaults.set(date, forKey: getKey(for: userId))
    }
    
    func needsReset(for userId: String) -> Bool {
        guard let lastReset = getLastResetDate(for: userId) else {
            print("DEBUG: No last reset date found - first time reset needed")
            return true  // Need reset on first signup to establish reset date
        }
        
        let calendar = Calendar.current
        let lastResetDay = calendar.startOfDay(for: lastReset)
        let today = calendar.startOfDay(for: Date())
        
        print("DEBUG: Last reset: \(lastResetDay)")
        print("DEBUG: Today: \(today)")
        print("DEBUG: Needs reset: \(lastResetDay < today)")
        
        return lastResetDay < today
    }
    
    func updateLastReset(for userId: String) {
        setLastResetDate(Date(), for: userId)
    }
    
    func getMissedDays(for userId: String) -> [Date] {
        guard let lastReset = getLastResetDate(for: userId) else {
            return []  // No missed days if this is first time
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastResetDay = calendar.startOfDay(for: lastReset)
        
        // Calculate days between last reset and today
        var missedDays: [Date] = []
        var currentDate = calendar.date(byAdding: .day, value: 1, to: lastResetDay) ?? today
        
        while currentDate < today {
            missedDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
        }
        
        return missedDays
    }
} 