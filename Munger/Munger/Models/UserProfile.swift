//
//  UserProfile.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import FirebaseAuth

struct UserProfile: Codable {
    let uid: String
    let email: String
    var watchlist: [String] // Store CIKs of watched companies
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
        self.watchlist = []
    }
}
