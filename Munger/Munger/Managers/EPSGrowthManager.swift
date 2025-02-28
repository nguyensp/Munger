//
//  EPSGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

struct EPSGrowthMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class EPSGrowthManager: BaseMetricManager<EPSGrowthMetricYear> {
    private let requiredKeys = ["NetIncomeLoss", "CommonStockSharesOutstanding"]
    
    init() {
        super.init(storageKey: "WatchedEPSGrowthMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> EPSGrowthMetricYear {
        return EPSGrowthMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherEPSGrowthMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    func epsGrowthReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateEPSForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let netIncome = getMetricValue(companyCik: companyCik, year: year, key: "NetIncomeLoss", facts: facts),
              let sharesOutstanding = getMetricValue(companyCik: companyCik, year: year, key: "CommonStockSharesOutstanding", facts: facts),
              sharesOutstanding != 0 else { return nil }
        
        return netIncome / sharesOutstanding
    }
    
    func calculateEPSGrowth(companyCik: Int, period: Int, facts: CompanyFacts) -> Double? {
        let availableYears = epsGrowthReadyYears(companyCik: companyCik, facts: facts)
        let recentYears = Array(availableYears.prefix(period))
        
        if recentYears.count < 2 { return nil } // Need at least 2 years for growth rate
        
        let latestYear = recentYears.first!
        let earliestYear = recentYears.last!
        let yearsDifference = latestYear - earliestYear
        
        guard let latestEPS = calculateEPSForYear(companyCik: companyCik, year: latestYear, facts: facts),
              let earliestEPS = calculateEPSForYear(companyCik: companyCik, year: earliestYear, facts: facts),
              earliestEPS != 0 else { return nil }
        
        return calculateCAGR(startValue: earliestEPS, endValue: latestEPS, years: yearsDifference)
    }
}
