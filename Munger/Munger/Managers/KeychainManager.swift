//
//  KeychainManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/19/25.
//

import Foundation
import KeychainAccess

struct KeychainManager {
    private static let keychain = Keychain(service: "personal.Munger") // Adjust if needed to match CFBundleIdentifier
    private static let emailKey = "userEmail"
    private static let passwordKey = "userPassword"
    
    static func saveCredentials(email: String, password: String) throws {
        try keychain.set(email, key: emailKey)
        try keychain.set(password, key: passwordKey)
        print("🔑 Saved credentials - email: \(email), password: [hidden]")
    }
    
    static func getCredentials() -> (email: String?, password: String?) {
        let email = try? keychain.get(emailKey)
        let password = try? keychain.get(passwordKey)
        print("🔑 Retrieved credentials - email: \(email ?? "nil"), password: \(password != nil ? "[present]" : "nil")")
        return (email, password)
    }
    
    static func clearCredentials() throws {
        try keychain.remove(emailKey)
        try keychain.remove(passwordKey)
        print("🔑 Cleared credentials")
    }
    
    static func hasCredentials() -> Bool {
        let (email, password) = getCredentials()
        let hasCreds = email != nil && password != nil
        print("🔑 Has credentials? \(hasCreds)")
        return hasCreds
    }
}
