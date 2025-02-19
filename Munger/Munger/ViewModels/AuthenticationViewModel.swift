//
//  AuthenticationViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
        self.user = authService.getCurrentUser()
        self.isAuthenticated = user != nil
        print("🛠️ AuthViewModel initialized, user: \(user?.email ?? "nil"), isAuthenticated: \(isAuthenticated)")
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authService.setupAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
                print("🔄 Auth state changed, user: \(user?.email ?? "nil"), isAuthenticated: \(self?.isAuthenticated ?? false)")
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task { @MainActor in
            do {
                user = try await authService.signIn(email: email, password: password)
                isAuthenticated = true
                error = nil
                print("✅ Sign-in successful, user: \(user?.email ?? "nil"), isAuthenticated: \(isAuthenticated)")
            } catch {
                self.error = error
                isAuthenticated = false
                print("❌ Sign-in failed, error: \(error.localizedDescription)")
            }
        }
    }
    
    func signUp(email: String, password: String) {
        Task {
            do {
                user = try await authService.signUp(email: email, password: password)
                isAuthenticated = true
                error = nil
            } catch {
                self.error = error
                isAuthenticated = false
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            user = nil
            isAuthenticated = false
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func resetPassword(email: String) {
        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                // You might want to show a success message
            } catch {
                self.error = error
            }
        }
    }
}
