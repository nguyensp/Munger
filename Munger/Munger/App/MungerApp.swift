//
//  MungerApp.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

// App/MungerApp.swift
import SwiftUI
import FirebaseCore

@main
struct MungerApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                SUIAuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

/**
 TODO:
- Swift Charts
- AI Thesis Generator
- Code Review
- Add Unit Tests
*/
