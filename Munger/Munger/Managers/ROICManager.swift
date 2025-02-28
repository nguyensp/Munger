//
//  ROICManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

// Add this to ROICManager.swift
struct MetricYear: Hashable, Codable {
    let metricKey: String
    let year: Int
}

struct ROICMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class ROICManager: BaseMetricManager<ROICMetricYear> {
    private let requiredKeys = ["NetIncomeLoss", "Assets", "LiabilitiesCurrent"]
    
    init() {
        super.init(storageKey: "WatchedROICMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> ROICMetricYear {
        return ROICMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherROICMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    func roicReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateROICForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let netIncome = getMetricValue(companyCik: companyCik, year: year, key: "NetIncomeLoss", facts: facts),
              let assets = getMetricValue(companyCik: companyCik, year: year, key: "Assets", facts: facts),
              let currentLiabilities = getMetricValue(companyCik: companyCik, year: year, key: "LiabilitiesCurrent", facts: facts),
              assets - currentLiabilities != 0 else { return nil }
        
        let investedCapital = assets - currentLiabilities
        return netIncome / investedCapital
    }
    
    func calculateROICAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = roicReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 <= yearsCount }) {
            let recentYears = Array(availableYears.prefix(period))
            if !recentYears.isEmpty {
                let roicValues = recentYears.compactMap { year in
                    calculateROICForYear(companyCik: companyCik, year: year, facts: facts)
                }
                if !roicValues.isEmpty {
                    let avg = roicValues.reduce(0.0, +) / Double(roicValues.count)
                    averages[period] = avg * 100 // Store as percentage
                }
            }
        }
        
        return averages
    }
}

