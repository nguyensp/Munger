//
//  FinancialThesisData.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import Foundation

struct FinancialThesisData: Codable {
    let companyCik: Int
    let companyName: String
    let roic: [Int: Double] // Year -> ROIC (%)
    let epsGrowth: [Int: Double] // StartYear -> Growth (%)
    let salesGrowth: [Int: Double]
    let bookValueGrowth: [Int: Double]
    let fcfGrowth: [Int: Double]
    let roicAverages: [Int: Double] // Period -> Avg ROIC (%)
    let epsGrowthAverages: [Int: Double]
    let salesGrowthAverages: [Int: Double]
    let bookValueGrowthAverages: [Int: Double]
    let fcfGrowthAverages: [Int: Double]
    
    static func generate(from facts: CompanyFacts,
                        roicManager: ROICManager,
                        epsManager: EPSGrowthManager,
                        salesManager: SalesGrowthManager,
                        bvManager: BookValueGrowthManager,
                        fcfManager: FCFGrowthManager,
                        periods: [Int] = [10, 7, 5, 3, 1]) -> FinancialThesisData {
        let cik = facts.cik
        let name = facts.entityName
        
        // Gather data
        roicManager.gatherROICMetrics(companyCik: cik, facts: facts)
        epsManager.gatherEPSMetrics(companyCik: cik, facts: facts)
        salesManager.gatherSalesMetrics(companyCik: cik, facts: facts)
        bvManager.gatherBookValueMetrics(companyCik: cik, facts: facts)
        fcfManager.gatherFCFMetrics(companyCik: cik, facts: facts)
        
        // Calculate single-year/period results
        let roicYears = roicManager.roicReadyYears(companyCik: cik, facts: facts)
        let epsYears = epsManager.epsReadyYears(companyCik: cik, facts: facts)
        let salesYears = salesManager.salesReadyYears(companyCik: cik, facts: facts)
        let bvYears = bvManager.bookValueReadyYears(companyCik: cik, facts: facts)
        let fcfYears = fcfManager.fcfReadyYears(companyCik: cik, facts: facts)
        
        var roic: [Int: Double] = [:]
        var epsGrowth: [Int: Double] = [:]
        var salesGrowth: [Int: Double] = [:]
        var bvGrowth: [Int: Double] = [:]
        var fcfGrowth: [Int: Double] = [:]
        
        // ROIC per year
        for year in roicYears {
            roic[year] = roicManager.calculateROICForYear(companyCik: cik, year: year, facts: facts).map { $0 * 100 }
        }
        
        // Growth rates year-over-year
        for i in 0..<(epsYears.count - 1) {
            let start = epsYears[i + 1]
            let end = epsYears[i]
            epsGrowth[start] = epsManager.calculateEPSGrowthForYears(companyCik: cik, startYear: start, endYear: end, facts: facts)
        }
        for i in 0..<(salesYears.count - 1) {
            let start = salesYears[i + 1]
            let end = salesYears[i]
            salesGrowth[start] = salesManager.calculateSalesGrowthForYears(companyCik: cik, startYear: start, endYear: end, facts: facts)
        }
        for i in 0..<(bvYears.count - 1) {
            let start = bvYears[i + 1]
            let end = bvYears[i]
            bvGrowth[start] = bvManager.calculateBookValueGrowthForYears(companyCik: cik, startYear: start, endYear: end, facts: facts)
        }
        for i in 0..<(fcfYears.count - 1) {
            let start = fcfYears[i + 1]
            let end = fcfYears[i]
            fcfGrowth[start] = fcfManager.calculateFCFGrowthForYears(companyCik: cik, startYear: start, endYear: end, facts: facts)
        }
        
        // Averages over periods
        let roicAverages = roicManager.calculateROICAverages(companyCik: cik, facts: facts, periods: periods)
        let epsAverages = epsManager.calculateEPSGrowthAverages(companyCik: cik, facts: facts, periods: periods)
        let salesAverages = salesManager.calculateSalesGrowthAverages(companyCik: cik, facts: facts, periods: periods)
        let bvAverages = bvManager.calculateBookValueGrowthAverages(companyCik: cik, facts: facts, periods: periods)
        let fcfAverages = fcfManager.calculateFCFGrowthAverages(companyCik: cik, facts: facts, periods: periods)
        
        return FinancialThesisData(
            companyCik: cik,
            companyName: name,
            roic: roic,
            epsGrowth: epsGrowth,
            salesGrowth: salesGrowth,
            bookValueGrowth: bvGrowth,
            fcfGrowth: fcfGrowth,
            roicAverages: roicAverages,
            epsGrowthAverages: epsAverages,
            salesGrowthAverages: salesAverages,
            bookValueGrowthAverages: bvAverages,
            fcfGrowthAverages: fcfAverages
        )
    }
}
