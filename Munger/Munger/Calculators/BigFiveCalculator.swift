//
//  BigFiveCalculator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation

struct HistoricalGrowthRates {
    let tenYear: Double?
    let sevenYear: Double?
    let fiveYear: Double?
    let threeYear: Double?
    
    var average: Double? {
        let rates = [tenYear, sevenYear, fiveYear, threeYear].compactMap { $0 }
        return rates.isEmpty ? nil : rates.reduce(0, +) / Double(rates.count)
    }
}

struct BigFiveMetrics: Identifiable {
    let year: Int
    let roic: Double
    let salesGrowth: HistoricalGrowthRates?
    let epsGrowth: HistoricalGrowthRates?
    let equityGrowth: HistoricalGrowthRates?
    let fcfGrowth: HistoricalGrowthRates?
    
    var id: Int { year }
    
    var estimatedFutureGrowthRate: Double? {
        let averages = [
            salesGrowth?.average,
            epsGrowth?.average,
            equityGrowth?.average,
            fcfGrowth?.average
        ].compactMap { $0 }
        
        guard !averages.isEmpty else { return nil }
        let overallAverage = averages.reduce(0, +) / Double(averages.count)
        
        return overallAverage
    }
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
            let investedCapital = assets - cash - totalLiabilities + longTermDebt + longTermInvestments
            let roic = investedCapital != 0 ? (nopat / investedCapital) * 100 : 0
            
            return BigFiveMetrics(
                year: year,
                roic: roic,
                salesGrowth: calculateHistoricalRates(values: salesByYear, currentYear: year),
                epsGrowth: calculateHistoricalRates(values: epsByYear, currentYear: year),
                equityGrowth: calculateHistoricalRates(values: equityByYear, currentYear: year),
                fcfGrowth: calculateHistoricalRates(values: fcfByYear, currentYear: year)
            )
        }
    }
    
    private func calculateHistoricalRates(values: [Int: Double], currentYear: Int) -> HistoricalGrowthRates? {
        // Check if we have enough historical data
        guard values.keys.contains(currentYear - 10) else { return nil }
        
        return HistoricalGrowthRates(
            tenYear: calculateCAGR(values: values, fromYear: currentYear - 10, toYear: currentYear),
            sevenYear: calculateCAGR(values: values, fromYear: currentYear - 7, toYear: currentYear),
            fiveYear: calculateCAGR(values: values, fromYear: currentYear - 5, toYear: currentYear),
            threeYear: calculateCAGR(values: values, fromYear: currentYear - 3, toYear: currentYear)
        )
    }
    
    private func calculateCAGR(values: [Int: Double], fromYear: Int, toYear: Int) -> Double? {
        guard let startValue = values[fromYear],
              let endValue = values[toYear],
              startValue != 0,
              fromYear != toYear else {
            return nil
        }
        
        let years = Double(toYear - fromYear)
        return (pow(endValue / startValue, 1.0 / years) - 1.0) * 100
    }
    
    // Existing helper methods remain the same
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
            ocf - capexValue
        }
    }
    
    private func calculateEffectiveTaxRate(operatingIncome: Double) -> Double {
        let defaultTaxRate = 0.21
        
        let incomeTaxExpense = groupMetricByYear("IncomeTaxExpense")
            .values
            .first ?? 0
        
        let incomeBeforeTax = groupMetricByYear("IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest")
            .values
            .first ?? 0
        
        if incomeBeforeTax > 0 {
            let effectiveRate = incomeTaxExpense / incomeBeforeTax
            return min(max(effectiveRate, 0), 0.5)
        }
        
        return defaultTaxRate
    }
}
