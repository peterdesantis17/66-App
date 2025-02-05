import Foundation
import Supabase
import GoTrue

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Supabase.User?
    @Published var errorMessage: String?
    
    static let shared = AuthManager()
    private let supabase = SupabaseManager.shared
    
    init() {
        // Check for existing session
        Task {
            do {
                currentUser = try await supabase.auth.session.user
                print("Auth init - Current user: \(String(describing: currentUser))")
                print("Auth init - Session: \(try await supabase.auth.session)")
                isAuthenticated = currentUser != nil
            } catch {
                print("Auth init error: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user
            isAuthenticated = currentUser != nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in response: \(response)")
            currentUser = response.user
            isAuthenticated = currentUser != nil
        } catch {
            print("Sign in error: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
} 
