//
//  AuthenticationViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import Foundation
import FirebaseAuth
import Combine
import LocalAuthentication

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let authService: ServiceAuthentication
    
    init(authService: ServiceAuthentication) {
        self.authService = authService
        self.user = authService.getCurrentUser()
        self.isAuthenticated = user != nil
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authService.setupAuthStateListener { [weak self] user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                user = try await authService.signIn(email: email, password: password)
                isAuthenticated = true
                error = nil
                try KeychainManager.saveCredentials(email: email, password: password)
            } catch {
                self.error = error
                isAuthenticated = false
            }
        }
    }
    
    func signInWithFaceID() {
        Task {
            print("👀 Attempting Face ID sign-in")
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                self.error = error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Biometrics unavailable"])
                print("❌ Face ID unavailable: \(self.error?.localizedDescription ?? "Unknown")")
                return
            }
            
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in to Munger with Face ID")
                print("👀 Face ID evaluation result: \(success)")
                if success {
                    let (email, password) = KeychainManager.getCredentials()
                    guard let email = email, let password = password else {
                        self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No saved credentials for Face ID"])
                        print("❌ No credentials found")
                        return
                    }
                    user = try await authService.signIn(email: email, password: password)
                    isAuthenticated = true
                    error = nil
                    print("✅ Face ID sign-in succeeded")
                } else {
                    print("❌ Face ID authentication failed")
                }
            } catch {
                self.error = error
                print("❌ Face ID error: \(error.localizedDescription)")
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
