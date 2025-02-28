//
//  MungerApp.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI
import FirebaseCore

/**
 TODO:
- Swift Charts
- AI Thesis Generator
- Growth Rate Calculators
- Additional Unit Tests
- Main View as Collection View
*/
@main
struct MungerApp: App {
    private let serviceFactory: ServiceFactoryProtocol
    
    init() {
        self.serviceFactory = ServiceFactory()
        do {
            try FirebaseApp.configure()
        } catch {
            fatalError("Firebase configuration failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SUIRootView(serviceFactory: serviceFactory)
        }
    }
}

