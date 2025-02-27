//
//  MetricsWatchListManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

class MetricsWatchListManager: ObservableObject {
    @Published private(set) var watchedMetricYears: [String: Set<MetricYear>]
    private let userDefaults = UserDefaults.standard
    private let storageKey = "WatchedMetricYears"
    
    struct MetricYear: Hashable, Codable {
        let metricKey: String
        let year: Int
    }
    
    init() {
        watchedMetricYears = [:]
        loadWatchedMetricYears()
    }
    
    func toggleMetricYear(companyCik: Int, metricKey: String, year: Int) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<MetricYear>()
        let metricYear = MetricYear(metricKey: metricKey, year: year)
        
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
        
        watchedMetricYears = updatedWatched
        saveWatchedMetricYears()
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
    
    func gatherROICMetrics(companyCik: Int, facts: CompanyFacts) {
        let requiredKeys = ["NetIncomeLoss", "Assets", "LiabilitiesCurrent"]
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<MetricYear>()
        
        guard let usGaap = facts.facts.usGaap else { return }
        
        for key in requiredKeys {
            if let metricData = usGaap[key],
               let dataPoints = metricData.units["USD"]?.filter({ $0.isAnnual }) {
                for dataPoint in dataPoints {
                    metricYears.insert(MetricYear(metricKey: key, year: dataPoint.fy))
                }
            }
        }
        
        if metricYears.isEmpty {
            updatedWatched.removeValue(forKey: cikKey)
        } else {
            updatedWatched[cikKey] = metricYears
        }
        
        watchedMetricYears = updatedWatched
        saveWatchedMetricYears()
    }
    
    func roicReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        guard let watched = watchedMetricYears[String(companyCik)],
              let usGaap = facts.facts.usGaap else { return [] }
        
        let requiredKeys = Set(["NetIncomeLoss", "Assets", "LiabilitiesCurrent"])
        let years = Set(watched.map { $0.year })
        
        return years.filter { year in
            requiredKeys.allSatisfy { key in
                usGaap[key]?.units["USD"]?.contains(where: { $0.fy == year && $0.isAnnual }) ?? false
            }
        }.sorted(by: >)
    }
    
    func calculateROICForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let usGaap = facts.facts.usGaap else { return nil }
        
        let netIncomeKey = "NetIncomeLoss"
        let assetsKey = "Assets"
        let liabilitiesKey = "LiabilitiesCurrent"
        
        let netIncome = usGaap[netIncomeKey]?.units["USD"]?.first(where: { $0.fy == year && $0.isAnnual })?.val
        let assets = usGaap[assetsKey]?.units["USD"]?.first(where: { $0.fy == year && $0.isAnnual })?.val
        let liabilities = usGaap[liabilitiesKey]?.units["USD"]?.first(where: { $0.fy == year && $0.isAnnual })?.val
        
        guard let nopat = netIncome, // Simplified NOPAT
              let totalAssets = assets,
              let currentLiabilities = liabilities,
              totalAssets - currentLiabilities != 0 else { return nil }
        
        let investedCapital = totalAssets - currentLiabilities
        return nopat / investedCapital
    }
}
