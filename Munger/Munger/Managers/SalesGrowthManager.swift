//
//  SalesGrowthManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

struct SalesGrowthMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class SalesGrowthManager: BaseMetricManager<SalesGrowthMetricYear> {
    private let requiredKeys = ["Revenues"]
    
    init() {
        super.init(storageKey: "WatchedSalesGrowthMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> SalesGrowthMetricYear {
        return SalesGrowthMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherSalesGrowthMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    func salesGrowthReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateSalesGrowth(companyCik: Int, period: Int, facts: CompanyFacts) -> Double? {
        let availableYears = salesGrowthReadyYears(companyCik: companyCik, facts: facts)
        let recentYears = Array(availableYears.prefix(period))
        
        if recentYears.count < 2 { return nil } // Need at least 2 years for growth rate
        
        let latestYear = recentYears.first!
        let earliestYear = recentYears.last!
        let yearsDifference = latestYear - earliestYear
        
        guard let latestSales = getMetricValue(companyCik: companyCik, year: latestYear, key: "Revenues", facts: facts),
              let earliestSales = getMetricValue(companyCik: companyCik, year: earliestYear, key: "Revenues", facts: facts),
              earliestSales != 0 else { return nil }
        
        return calculateCAGR(startValue: earliestSales, endValue: latestSales, years: yearsDifference)
    }
}
