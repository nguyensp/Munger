//
//  MungerApp.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI
import FirebaseCore

@main
struct MungerApp: App {
    private let serviceFactory: ServiceFactoryProtocol = ServiceFactory()
    
    init() {
        do {
            try FirebaseApp.configure()
        } catch {
            print("Firebase config failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SUIRootView(serviceFactory: serviceFactory)
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
