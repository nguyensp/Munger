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
        let totalLiabilitiesByYear = groupMetricByYear("Liabilities")
        let longTermInvestmentsByYear = groupMetricByYear("LongTermInvestments")
        let longTermDebtByYear = groupMetricByYear("LongTermDebtNoncurrent")
        let salesByYear = groupMetricByYear("Revenues")
        let epsByYear = groupMetricByYear("EarningsPerShareBasic")
        let equityByYear = groupMetricByYear("StockholdersEquity")
        let fcfByYear = calculateFCFByYear()
        
        // Get intersection of all required years for ROIC calculation
        let years = Set(operatingIncomeByYear.keys)
            .intersection(Set(assetsByYear.keys))
            .intersection(Set(cashByYear.keys))
            .intersection(Set(totalLiabilitiesByYear.keys))
            .sorted(by: >)
        
        return years.compactMap { year in
            guard let operatingIncome = operatingIncomeByYear[year],
                  let assets = assetsByYear[year],
                  let cash = cashByYear[year],
                  let totalLiabilities = totalLiabilitiesByYear[year] else {
                return nil
            }
            
            // Get optional values
            let longTermInvestments = longTermInvestmentsByYear[year] ?? 0
            let longTermDebt = longTermDebtByYear[year] ?? 0
            
            // Calculate ROIC
            let effectiveTaxRate = calculateEffectiveTaxRate(operatingIncome: operatingIncome)
            let nopat = operatingIncome * (1 - effectiveTaxRate)
            
            // Invested Capital = Total Assets - Cash - Total Liabilities + Long Term Debt + Long Term Investments
            let investedCapital = assets - cash - totalLiabilities + longTermDebt + longTermInvestments
            
            // Calculate ROIC as percentage
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
            ocf - capexValue  // Subtract capex from operating cash flow
        }
    }
    
    private func calculateEffectiveTaxRate(operatingIncome: Double) -> Double {
        // Default corporate tax rate if we can't calculate effective rate
        let defaultTaxRate = 0.21
        
        // Get income tax expense and income before tax
        let incomeTaxExpense = groupMetricByYear("IncomeTaxExpense")
            .values
            .first ?? 0
        
        let incomeBeforeTax = groupMetricByYear("IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest")
            .values
            .first ?? 0
        
        // Calculate effective tax rate or return default
        if incomeBeforeTax > 0 {
            let effectiveRate = incomeTaxExpense / incomeBeforeTax
            // Ensure rate is reasonable (between 0% and 50%)
            return min(max(effectiveRate, 0), 0.5)
        }
        
        return defaultTaxRate
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
