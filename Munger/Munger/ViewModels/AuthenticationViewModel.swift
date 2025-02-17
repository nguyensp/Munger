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
    
    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
        self.user = authService.getCurrentUser()
        self.isAuthenticated = user != nil
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authService.setupAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                user = try await authService.signIn(email: email, password: password)
                isAuthenticated = true
                error = nil
            } catch {
                self.error = error
                isAuthenticated = false
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
