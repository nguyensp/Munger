//
//  AuthenticationService.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import FirebaseAuth
import Foundation

class AuthenticationService {
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func setupAuthStateListener(completion: @escaping (User?) -> Void) {
        Auth.auth().addStateDidChangeListener { _, user in
            completion(user)
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
