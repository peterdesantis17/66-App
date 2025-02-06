/**
 Manages Supabase client instance and session state.
 
 Note: When simulating future dates (e.g., changing system time), session tokens may become invalid
 as they are time-sensitive. This only affects development/testing scenarios and does not impact
 real-world usage where time progresses normally.
 */
class SupabaseManager {
    static let shared = SupabaseManager()
    private var client: SupabaseClient?
    private let clientId = UUID() // To track client instance
    private var lastSessionCheck: Date?
    private let sessionCheckThreshold: TimeInterval = 60 // Check session every minute
    
    private init() {
        print("🔧 SupabaseManager: Initializing new instance \(clientId)")
    }
    
    var supabase: SupabaseClient {
        if let client = client {
            if shouldRefreshSession {
                print("⏰ SupabaseManager: Session check threshold reached")
                Task {
                    do {
                        print("🔄 SupabaseManager: Checking session status")
                        let session = try await client.auth.session
                        print("✅ SupabaseManager: Session valid until \(Date(timeIntervalSince1970: session.expiresAt))")
                        lastSessionCheck = Date()
                    } catch {
                        print("❌ SupabaseManager: Session check failed - \(error)")
                        self.client = nil  // Force new client creation
                    }
                }
            }
            return client
        }
        
        print("🔧 SupabaseManager[\(clientId)]: Creating new Supabase client")
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://jyfbqrlwlamcpehusodk.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5ZmJxcmx3bGFtY3BlaHVzb2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTU1ODgsImV4cCI6MjA1NDA5MTU4OH0.RM0p3o3kTdMt5Eh7beu3goUj3UKXcAW18WA2G1wldYU"
        )
        self.client = client
        self.lastSessionCheck = Date()
        return client
    }
    
    private var shouldRefreshSession: Bool {
        guard let lastCheck = lastSessionCheck else { return true }
        return Date().timeIntervalSince(lastCheck) > sessionCheckThreshold
    }
} 