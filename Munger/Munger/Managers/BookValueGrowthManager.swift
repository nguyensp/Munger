//
//  BookValueGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import Foundation

struct BookValueMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

/// Calculate Book Value (Equity) Growth
class BookValueGrowthManager: BaseMetricManager<BookValueMetricYear> {
    private let requiredKeys = ["StockholdersEquity"]
    
    init() {
        super.init(storageKey: "WatchedBookValueMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> BookValueMetricYear {
        return BookValueMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherBookValueMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    override func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<BookValueMetricYear>()
        
        guard let usGaap = facts.facts.usGaap else { return }
        
        for key in requiredKeys {
            guard requiredKeys.contains(key) else { continue }
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
    
    func bookValueReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateBookValueGrowthForYears(companyCik: Int, startYear: Int, endYear: Int, facts: CompanyFacts) -> Double? {
        guard let startBV = getMetricValue(companyCik: companyCik, year: startYear, key: "StockholdersEquity", facts: facts),
              let endBV = getMetricValue(companyCik: companyCik, year: endYear, key: "StockholdersEquity", facts: facts),
              startBV != 0 else { return nil }
        return ((endBV - startBV) / startBV) * 100
    }
    
    func calculateBookValueGrowthAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = bookValueReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 < yearsCount }) {
            let recentYears = Array(availableYears.prefix(period + 1))
            if recentYears.count > 1 {
                let growthValues = (1..<recentYears.count).compactMap { i in
                    calculateBookValueGrowthForYears(companyCik: companyCik, startYear: recentYears[i-1], endYear: recentYears[i], facts: facts)
                }
                if !growthValues.isEmpty {
                    averages[period] = growthValues.reduce(0.0, +) / Double(growthValues.count)
                }
            }
        }
        
        return averages
    }
    
    func clearMetrics(companyCik: Int) {
        var updatedWatched = watchedMetricYears
        let cikKey = String(companyCik)
        updatedWatched.removeValue(forKey: cikKey)
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
    }
}
