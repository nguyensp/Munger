//
//  FreeCashFlowManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

struct FreeCashFlowMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class FreeCashFlowManager: BaseMetricManager<FreeCashFlowMetricYear> {
    private let requiredKeys = ["NetCashProvidedByUsedInOperatingActivities", "PaymentsToAcquirePropertyPlantAndEquipment"]
    
    init() {
        super.init(storageKey: "WatchedFreeCashFlowMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> FreeCashFlowMetricYear {
        return FreeCashFlowMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherFreeCashFlowMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    func freeCashFlowReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateFreeCashFlowForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let operatingCashFlow = getMetricValue(companyCik: companyCik, year: year, key: "NetCashProvidedByUsedInOperatingActivities", facts: facts) else { return nil }
        
        // CapEx might be nil or 0, which is valid for some companies
        let capEx = getMetricValue(companyCik: companyCik, year: year, key: "PaymentsToAcquirePropertyPlantAndEquipment", facts: facts) ?? 0
        
        return operatingCashFlow - capEx
    }
    
    func calculateFreeCashFlowGrowth(companyCik: Int, period: Int, facts: CompanyFacts) -> Double? {
        let availableYears = freeCashFlowReadyYears(companyCik: companyCik, facts: facts)
        let recentYears = Array(availableYears.prefix(period))
        
        if recentYears.count < 2 { return nil } // Need at least 2 years for growth rate
        
        let latestYear = recentYears.first!
        let earliestYear = recentYears.last!
        let yearsDifference = latestYear - earliestYear
        
        guard let latestFCF = calculateFreeCashFlowForYear(companyCik: companyCik, year: latestYear, facts: facts),
              let earliestFCF = calculateFreeCashFlowForYear(companyCik: companyCik, year: earliestYear, facts: facts),
              earliestFCF != 0 else { return nil }
        
        return calculateCAGR(startValue: earliestFCF, endValue: latestFCF, years: yearsDifference)
    }
    
    // FCF Yield: Free Cash Flow / Market Cap (if available)
    func calculateFCFYield(companyCik: Int, year: Int, facts: CompanyFacts, marketCap: Double) -> Double? {
        guard let fcf = calculateFreeCashFlowForYear(companyCik: companyCik, year: year, facts: facts),
              marketCap > 0 else { return nil }
        
        return fcf / marketCap
    }
}
