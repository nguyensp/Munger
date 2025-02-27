//
//  MetricsWatchListManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

class MetricsWatchListManager: ObservableObject {
    @Published private(set) var watchedMetricYears: [String: Set<MetricYear>] = [:] // [CIK: Set<(metricKey, year)>]
    private let userDefaults = UserDefaults.standard
    private let storageKey = "WatchedMetricYears"
    
    struct MetricYear: Hashable, Codable { // Add Codable for JSON
        let metricKey: String
        let year: Int
    }
    
    init() {
        loadWatchedMetricYears() // Load on init
    }
    
    func toggleMetricYear(companyCik: Int, metricKey: String, year: Int) {
        let cikKey = String(companyCik)
        var metricYears = watchedMetricYears[cikKey] ?? Set<MetricYear>()
        let metricYear = MetricYear(metricKey: metricKey, year: year)
        if metricYears.contains(metricYear) {
            metricYears.remove(metricYear)
        } else {
            metricYears.insert(metricYear)
        }
        watchedMetricYears[cikKey] = metricYears.isEmpty ? nil : metricYears
        saveWatchedMetricYears() // Save after every change
    }
    
    func isWatched(companyCik: Int, metricKey: String, year: Int) -> Bool {
        watchedMetricYears[String(companyCik)]?.contains(MetricYear(metricKey: metricKey, year: year)) ?? false
    }
    
    private func loadWatchedMetricYears() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: Set<MetricYear>].self, from: data) {
            watchedMetricYears = decoded
        }
    }
    
    private func saveWatchedMetricYears() {
        if let encoded = try? JSONEncoder().encode(watchedMetricYears) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
