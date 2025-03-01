//
//  FCFGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import Foundation

struct FCFMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

/// Calculate Free Cash Flow Growth
class FCFGrowthManager: BaseMetricManager<FCFMetricYear> {
    private let requiredKeys = ["NetCashProvidedByUsedInOperatingActivities", "CapitalExpenditures"]
    
    init() {
        super.init(storageKey: "WatchedFCFMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> FCFMetricYear {
        return FCFMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherFCFMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    override func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<FCFMetricYear>()
        
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
    
    func fcfReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateFCFForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let operatingCash = getMetricValue(companyCik: companyCik, year: year, key: "NetCashProvidedByUsedInOperatingActivities", facts: facts),
              let capEx = getMetricValue(companyCik: companyCik, year: year, key: "CapitalExpenditures", facts: facts) else { return nil }
        return operatingCash - capEx // FCF = Operating Cash Flow - CapEx
    }
    
    func calculateFCFGrowthForYears(companyCik: Int, startYear: Int, endYear: Int, facts: CompanyFacts) -> Double? {
        guard let startFCF = calculateFCFForYear(companyCik: companyCik, year: startYear, facts: facts),
              let endFCF = calculateFCFForYear(companyCik: companyCik, year: endYear, facts: facts),
              startFCF != 0 else { return nil }
        return ((endFCF - startFCF) / startFCF) * 100
    }
    
    func calculateFCFGrowthAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = fcfReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 < yearsCount }) {
            let recentYears = Array(availableYears.prefix(period + 1))
            if recentYears.count > 1 {
                let growthValues = (1..<recentYears.count).compactMap { i in
                    calculateFCFGrowthForYears(companyCik: companyCik, startYear: recentYears[i-1], endYear: recentYears[i], facts: facts)
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
