//
//  EPSGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import Foundation

struct EPSMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

/// Calculate Earnings Per Share Growth
class EPSGrowthManager: BaseMetricManager<EPSMetricYear> {
    private let requiredKeys = ["EarningsPerShareBasic"]
    
    init() {
        super.init(storageKey: "WatchedEPSMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> EPSMetricYear {
        return EPSMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherEPSMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    override func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<EPSMetricYear>()
        
        guard let usGaap = facts.facts.usGaap else { return }
        
        for key in requiredKeys {
            guard requiredKeys.contains(key) else {
                print("Warning: Attempted to gather non-EPS metric \(key) in EPSGrowthManager")
                continue
            }
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
    
    func epsReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateEPSGrowthForYears(companyCik: Int, startYear: Int, endYear: Int, facts: CompanyFacts) -> Double? {
        guard let startEPS = getMetricValue(companyCik: companyCik, year: startYear, key: "EarningsPerShareBasic", facts: facts),
              let endEPS = getMetricValue(companyCik: companyCik, year: endYear, key: "EarningsPerShareBasic", facts: facts),
              startEPS != 0 else { return nil }
        return ((endEPS - startEPS) / startEPS) * 100 // Percentage growth
    }
    
    func calculateEPSGrowthAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = epsReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 < yearsCount }) { // Need at least 2 years for growth
            let recentYears = Array(availableYears.prefix(period + 1)) // Include start + end
            if recentYears.count > 1 {
                let growthValues = (1..<recentYears.count).compactMap { i in
                    calculateEPSGrowthForYears(companyCik: companyCik, startYear: recentYears[i-1], endYear: recentYears[i], facts: facts)
                }
                if !growthValues.isEmpty {
                    let avg = growthValues.reduce(0.0, +) / Double(growthValues.count)
                    averages[period] = avg
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
