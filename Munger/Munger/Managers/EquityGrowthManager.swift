//
//  EquityGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

struct EquityGrowthMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class EquityGrowthManager: BaseMetricManager<EquityGrowthMetricYear> {
    private let requiredKeys = ["StockholdersEquity"]
    
    init() {
        super.init(storageKey: "WatchedEquityGrowthMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> EquityGrowthMetricYear {
        return EquityGrowthMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherEquityGrowthMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    func equityGrowthReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateEquityGrowth(companyCik: Int, period: Int, facts: CompanyFacts) -> Double? {
        let availableYears = equityGrowthReadyYears(companyCik: companyCik, facts: facts)
        let recentYears = Array(availableYears.prefix(period))
        
        if recentYears.count < 2 { return nil } // Need at least 2 years for growth rate
        
        let latestYear = recentYears.first!
        let earliestYear = recentYears.last!
        let yearsDifference = latestYear - earliestYear
        
        guard let latestEquity = getMetricValue(companyCik: companyCik, year: latestYear, key: "StockholdersEquity", facts: facts),
              let earliestEquity = getMetricValue(companyCik: companyCik, year: earliestYear, key: "StockholdersEquity", facts: facts),
              earliestEquity != 0 else { return nil }
        
        return calculateCAGR(startValue: earliestEquity, endValue: latestEquity, years: yearsDifference)
    }
}
