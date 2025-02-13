//
//  WatchListManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation

class WatchListManager: ObservableObject {
    @Published private(set) var watchedCompanies: Set<Int> = []
    private let userDefaults = UserDefaults.standard
    private let watchListKey = "WatchedCompanies"
    
    init() {
        loadWatchList()
    }
    
    func loadWatchList() {
        if let data = userDefaults.data(forKey: watchListKey),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            watchedCompanies = decoded
        }
    }
    
    private func saveWatchList() {
        if let encoded = try? JSONEncoder().encode(watchedCompanies) {
            userDefaults.set(encoded, forKey: watchListKey)
        }
    }
    
    func toggleWatch(company: Company) {
        if watchedCompanies.contains(company.cik) {
            watchedCompanies.remove(company.cik)
        } else {
            watchedCompanies.insert(company.cik)
        }
        saveWatchList()
    }
    
    func isWatched(company: Company) -> Bool {
        watchedCompanies.contains(company.cik)
    }
}
