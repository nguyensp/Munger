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
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
        self.isAuthenticated = authService.getCurrentUser() != nil
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                _ = try await authService.signIn(email: email, password: password)
                self.isAuthenticated = true
            } catch {
                self.error = error
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            self.isAuthenticated = false
        } catch {
            self.error = error
        }
    }
    
    func signUp(email: String, password: String) {
        Task {
            do {
                _ = try await authService.signUp(email: email, password: password)
                self.isAuthenticated = true
            } catch {
                self.error = error
            }
        }
    }
}
