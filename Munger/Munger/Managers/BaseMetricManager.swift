//
//  BaseMetricManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/27/25.
//

import Foundation
import Combine

protocol MetricYearProtocol: Hashable, Codable {
    var metricKey: String { get }
    var year: Int { get }
}

class BaseMetricManager<T: MetricYearProtocol>: ObservableObject {
    @Published private(set) var watchedMetricYears: [String: Set<T>]
    private let userDefaults: UserDefaults
    /*protected*/ internal let storageKey: String
    
    init(storageKey: String, userDefaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.userDefaults = userDefaults
        watchedMetricYears = [:]
        loadWatchedMetricYears()
    }
    
    // Protected method to update watchedMetricYears
    /*protected*/ func updateWatchedMetricYears(_ newValue: [String: Set<T>]) {
        watchedMetricYears = newValue
    }
    
    func createMetricYear(metricKey: String, year: Int) -> T {
        fatalError("Must be implemented by subclass")
    }
    
    func toggleMetricYear(companyCik: Int, metricKey: String, year: Int) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<T>()
        let metricYear = createMetricYear(metricKey: metricKey, year: year)
        
        if metricYears.contains(metricYear) {
            metricYears.remove(metricYear)
        } else {
            metricYears.insert(metricYear)
        }
        
        if metricYears.isEmpty {
            updatedWatched.removeValue(forKey: cikKey)
        } else {
            updatedWatched[cikKey] = metricYears
        }
        
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
    }
    
    func isWatched(companyCik: Int, metricKey: String, year: Int) -> Bool {
        let metricYear = createMetricYear(metricKey: metricKey, year: year)
        return watchedMetricYears[String(companyCik)]?.contains(metricYear) ?? false
    }
    
    func loadWatchedMetricYears() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: Set<T>].self, from: data) {
            updateWatchedMetricYears(decoded)
        }
    }
    
    func saveWatchedMetricYears() {
        if let encoded = try? JSONEncoder().encode(watchedMetricYears) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<T>()
        
        guard let usGaap = facts.facts.usGaap else { return }
        
        for key in requiredKeys {
            if let metricData = usGaap[key],
               let dataPoints = metricData.units["USD"]?.filter({ $0.isAnnual }) {
                for dataPoint in dataPoints {
                    metricYears.insert(createMetricYear(metricKey: key, year: dataPoint.fy))
                }
            }
        }
        
        if metricYears.isEmpty {
            updatedWatched.removeValue(forKey: cikKey)
        } else {
            updatedWatched[cikKey] = metricYears
        }
        
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
    }
    
    func readyYears(companyCik: Int, facts: CompanyFacts, requiredKeys: Set<String>) -> [Int] {
        guard let watched = watchedMetricYears[String(companyCik)],
              let usGaap = facts.facts.usGaap else { return [] }
        
        let years = Set(watched.map { $0.year })
        
        return years.filter { year in
            requiredKeys.allSatisfy { key in
                usGaap[key]?.units["USD"]?.contains(where: { $0.fy == year && $0.isAnnual }) ?? false
            }
        }.sorted(by: >)
    }
    
    func getMetricValue(companyCik: Int, year: Int, key: String, facts: CompanyFacts) -> Double? {
        guard let usGaap = facts.facts.usGaap else { return nil }
        return usGaap[key]?.units["USD"]?.first(where: { $0.fy == year && $0.isAnnual })?.val
    }
}
