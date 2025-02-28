//
//  BigFiveCalculator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

/// Deprecated
import Foundation

struct HistoricalGrowthRates {
    let tenYear: Double?
    let sevenYear: Double?
    let fiveYear: Double?
    let threeYear: Double?
    
    var average: Double? { [tenYear, sevenYear, fiveYear, threeYear].compactMap { $0 }.average() }
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
        [salesGrowth?.average, epsGrowth?.average, equityGrowth?.average, fcfGrowth?.average].compactMap { $0 }.average()
    }
}

class BigFiveCalculator {
    private let facts: CompanyFacts
    private let logger = Logger()
    
    init(facts: CompanyFacts) {
        self.facts = facts
    }
    
    func calculateMetrics() -> [BigFiveMetrics] {
        let operatingIncome = groupAnnualMetric("OperatingIncomeLoss", unit: "USD")
        let assets = groupAnnualMetric("Assets", unit: "USD")
        let cash = groupAnnualMetric("CashAndCashEquivalentsAtCarryingValue", unit: "USD")
        let liabilities = groupAnnualMetric("Liabilities", unit: "USD")
        let longTermInvestments = groupAnnualMetric("MarketableSecuritiesNoncurrent", unit: "USD") // Fixed key
        let longTermDebt = groupAnnualMetric("LongTermDebtNoncurrent", unit: "USD")
        let sales = groupAnnualMetric("Revenues", unit: "USD")
        let epsBasic = groupAnnualMetric("EarningsPerShareBasic", unit: "pure")
        let epsDiluted = groupAnnualMetric("EarningsPerShareDiluted", unit: "pure")
        let eps = epsBasic.isEmpty ? epsDiluted : epsBasic
        let equity = groupAnnualMetric("StockholdersEquity", unit: "USD")
        let fcf = calculateFCFByYear()
        let incomeBeforeTax = groupAnnualMetric("IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest", unit: "USD")
        let taxExpense = groupAnnualMetric("IncomeTaxExpenseBenefit", unit: "USD")
        
        let requiredYears = Set(operatingIncome.keys)
            .intersection(assets.keys)
            .intersection(cash.keys)
            .intersection(liabilities.keys)
            .sorted()
        
        logger.log("Required years: \(requiredYears)")
        logger.log("Sales data: \(sales)")
        logger.log("EPS data (Basic): \(epsBasic)")
        logger.log("EPS data (Diluted): \(epsDiluted)")
        logger.log("EPS used: \(eps)")
        logger.log("FCF data: \(fcf)")
        
        return requiredYears.map { year in
            let opIncome = operatingIncome[year] ?? 0
            let assetValue = assets[year] ?? 0
            let cashValue = cash[year] ?? 0
            let liabilityValue = liabilities[year] ?? 0
            let ltInvestments = longTermInvestments[year] ?? 0
            let ltDebt = longTermDebt[year] ?? 0
            
            let taxRate = calculateEffectiveTaxRate(year: year, incomeBeforeTax: incomeBeforeTax, taxExpense: taxExpense)
            let nopat = opIncome * (1 - taxRate)
            let investedCapital = assetValue - cashValue - liabilityValue + ltDebt + ltInvestments
            let roic = investedCapital != 0 ? (nopat / investedCapital) * 100 : 0
            
            logger.log("Year \(year): ROIC = \(roic)%, NOPAT = \(nopat), Invested Capital = \(investedCapital)")
            
            return BigFiveMetrics(
                year: year,
                roic: roic,
                salesGrowth: calculateGrowthRates(data: sales, currentYear: year),
                epsGrowth: calculateGrowthRates(data: eps, currentYear: year),
                equityGrowth: calculateGrowthRates(data: equity, currentYear: year),
                fcfGrowth: calculateGrowthRates(data: fcf, currentYear: year)
            )
        }
    }
    
    private func groupAnnualMetric(_ metric: String, unit: String) -> [Int: Double] {
        guard let dataPoints = facts.facts.usGaap?[metric]?.units[unit] else {
            logger.log("No \(unit) data for \(metric)")
            return [:]
        }
        let annualPoints = dataPoints.filter { $0.isAnnual }
        guard !annualPoints.isEmpty else {
            logger.log("No annual data for \(metric)")
            return [:]
        }
        logger.log("Raw \(metric) annual points: \(annualPoints.map { "\($0.fy): \($0.val), Filed: \($0.filed)" })")
        let result = Dictionary(
            grouping: annualPoints,
            by: { $0.fy }
        ).mapValues { points in
            points.sorted { $0.filed > $1.filed }.first!.val
        }
        logger.log("\(metric) annual data points: \(result.count), Data: \(result)")
        return result
    }
    
    private func calculateFCFByYear() -> [Int: Double] {
        let operatingCashFlow = groupAnnualMetric("NetCashProvidedByUsedInOperatingActivities", unit: "USD")
        let capex = groupAnnualMetric("PaymentsToAcquirePropertyPlantAndEquipment", unit: "USD")
        
        var fcfByYear: [Int: Double] = [:]
        for (year, ocf) in operatingCashFlow {
            let capexValue = capex[year] ?? 0
            fcfByYear[year] = ocf - capexValue
            logger.log("FCF for \(year): \(ocf) - \(capexValue) = \(fcfByYear[year]!)")
        }
        return fcfByYear
    }
    
    private func calculateEffectiveTaxRate(year: Int, incomeBeforeTax: [Int: Double], taxExpense: [Int: Double]) -> Double {
        let defaultTaxRate = 0.21
        guard let income = incomeBeforeTax[year],
              let tax = taxExpense[year],
              income > 0 else {
            logger.log("Using default tax rate for year \(year)")
            return defaultTaxRate
        }
        let rate = tax / income
        logger.log("Tax rate for \(year): \(rate * 100)% (Tax: \(tax), Income: \(income))")
        return min(max(rate, 0), 0.5)
    }
    
    private func calculateGrowthRates(data: [Int: Double], currentYear: Int) -> HistoricalGrowthRates? {
        guard !data.isEmpty else {
            logger.log("No data for growth rates in year \(currentYear)")
            return nil
        }
        
        let periods = [3, 5, 7, 10]
        func cagr(from: Int) -> Double? {
            guard let startValue = data[currentYear - from],
                  let endValue = data[currentYear],
                  startValue > 0 else {
                logger.log("CAGR \(from)Y for \(currentYear): No data (start: \(data[currentYear - from] ?? 0), end: \(data[currentYear] ?? 0))")
                return nil
            }
            let years = Double(from)
            let growth = (pow(endValue / startValue, 1.0 / years) - 1) * 100
            logger.log("CAGR \(from)Y for \(currentYear): \(growth)% (\(startValue) to \(endValue))")
            return growth
        }
        
        return HistoricalGrowthRates(
            tenYear: cagr(from: 10),
            sevenYear: cagr(from: 7),
            fiveYear: cagr(from: 5),
            threeYear: cagr(from: 3)
        )
    }
}

struct Logger {
    func log(_ message: String) {
        //print("[BigFiveCalculator] \(message)")
    }
}
