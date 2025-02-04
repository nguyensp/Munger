//
//  BigFiveCalculator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation

struct BigFiveMetrics: Identifiable {
    let year: Int
    let roic: Double
    let salesGrowth: Double?
    let epsGrowth: Double?
    let equityGrowth: Double?
    let fcfGrowth: Double?
    
    var id: Int { year }
}

class BigFiveCalculator {
    private let facts: CompanyFacts
    
    init(facts: CompanyFacts) {
        self.facts = facts
    }
    
    func calculateMetrics() -> [BigFiveMetrics] {
        let operatingIncomeByYear = groupMetricByYear("OperatingIncomeLoss")
        let assetsByYear = groupMetricByYear("Assets")
        let cashByYear = groupMetricByYear("CashAndCashEquivalentsAtCarryingValue")
        let liabilitiesByYear = groupMetricByYear("LiabilitiesCurrent")
        let salesByYear = groupMetricByYear("Revenues")
        let epsByYear = groupMetricByYear("EarningsPerShareBasic")
        let equityByYear = groupMetricByYear("StockholdersEquity")
        let fcfByYear = calculateFCFByYear()
        
        let years = Set(operatingIncomeByYear.keys)
            .intersection(Set(assetsByYear.keys))
            .sorted(by: >)
        
        return years.compactMap { year in
            guard let operatingIncome = operatingIncomeByYear[year],
                  let assets = assetsByYear[year],
                  let cash = cashByYear[year],
                  let liabilities = liabilitiesByYear[year] else {
                return nil
            }
            
            let taxRate = 0.21
            let nopat = operatingIncome * (1 - taxRate)
            let investedCapital = assets - cash - liabilities
            let roic = investedCapital != 0 ? (nopat / investedCapital) * 100 : 0
            
            return BigFiveMetrics(
                year: year,
                roic: roic,
                salesGrowth: calculateGrowthRate(values: salesByYear, currentYear: year),
                epsGrowth: calculateGrowthRate(values: epsByYear, currentYear: year),
                equityGrowth: calculateGrowthRate(values: equityByYear, currentYear: year),
                fcfGrowth: calculateGrowthRate(values: fcfByYear, currentYear: year)
            )
        }
    }
    
    private func groupMetricByYear(_ metric: String) -> [Int: Double] {
        let dataPoints = facts.facts.usGaap[metric]?.units["USD"] ?? []
        return Dictionary(
            grouping: dataPoints,
            by: { $0.fy }
        ).mapValues { points in
            points.sorted(by: { $0.end > $1.end }).first?.val ?? 0
        }
    }
    
    private func calculateFCFByYear() -> [Int: Double] {
        let operatingCashFlow = groupMetricByYear("NetCashProvidedByUsedInOperatingActivities")
        let capex = groupMetricByYear("PaymentsToAcquirePropertyPlantAndEquipment")
        
        return operatingCashFlow.merging(capex) { ocf, capexValue in
            ocf + (capexValue)
        }
    }
    
    private func calculateGrowthRate(values: [Int: Double], currentYear: Int) -> Double? {
        guard let currentValue = values[currentYear],
              let previousValue = values[currentYear - 1],
              previousValue != 0 else {
            return nil
        }
        return ((currentValue - previousValue) / abs(previousValue)) * 100
    }
}
