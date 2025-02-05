import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://jyfbqrlwlamcpehusodk.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5ZmJxcmx3bGFtY3BlaHVzb2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTU1ODgsImV4cCI6MjA1NDA5MTU4OH0.RM0p3o3kTdMt5Eh7beu3goUj3UKXcAW18WA2G1wldYU"
    )
    
    static var shared: SupabaseClient {
        print("Getting shared Supabase client")
        return client
    }
} 
