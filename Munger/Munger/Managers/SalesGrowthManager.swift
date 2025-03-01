//
//  SalesGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import Foundation

struct SalesMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

/// Calculate Sales (Revenue) Growth
class SalesGrowthManager: BaseMetricManager<SalesMetricYear> {
    private let requiredKeys = ["Revenues", "SalesRevenueNet"] // Fallback if one’s missing
    
    init() {
        super.init(storageKey: "WatchedSalesMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> SalesMetricYear {
        return SalesMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherSalesMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    override func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<SalesMetricYear>()
        
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
    
    func salesReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateSalesGrowthForYears(companyCik: Int, startYear: Int, endYear: Int, facts: CompanyFacts) -> Double? {
        let salesKey = requiredKeys.first { getMetricValue(companyCik: companyCik, year: startYear, key: $0, facts: facts) != nil } ?? "Revenues"
        guard let startSales = getMetricValue(companyCik: companyCik, year: startYear, key: salesKey, facts: facts),
              let endSales = getMetricValue(companyCik: companyCik, year: endYear, key: salesKey, facts: facts),
              startSales != 0 else { return nil }
        return ((endSales - startSales) / startSales) * 100
    }
    
    func calculateSalesGrowthAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = salesReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 < yearsCount }) {
            let recentYears = Array(availableYears.prefix(period + 1))
            if recentYears.count > 1 {
                let growthValues = (1..<recentYears.count).compactMap { i in
                    calculateSalesGrowthForYears(companyCik: companyCik, startYear: recentYears[i-1], endYear: recentYears[i], facts: facts)
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
