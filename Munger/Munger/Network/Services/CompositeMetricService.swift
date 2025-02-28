//
//  CompositeMetricService.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation
import Combine

/// Service to calculate composite financial metrics derived from multiple financial data points
class CompositeMetricsService {
    private let roicManager: ROICManager
    private let epsGrowthManager: EPSGrowthManager
    private let salesGrowthManager: SalesGrowthManager
    private let equityGrowthManager: EquityGrowthManager
    private let freeCashFlowManager: FreeCashFlowManager
    
    init(roicManager: ROICManager,
         epsGrowthManager: EPSGrowthManager,
         salesGrowthManager: SalesGrowthManager,
         equityGrowthManager: EquityGrowthManager,
         freeCashFlowManager: FreeCashFlowManager) {
        self.roicManager = roicManager
        self.epsGrowthManager = epsGrowthManager
        self.salesGrowthManager = salesGrowthManager
        self.equityGrowthManager = equityGrowthManager
        self.freeCashFlowManager = freeCashFlowManager
    }
    
    // MARK: - Value Creation Score
    
    /// Calculate a Value Creation Score based on ROIC and Growth metrics
    /// Scale of 0-100, with higher scores indicating better value creation
    func calculateValueCreationScore(companyCik: Int, facts: CompanyFacts) -> Double? {
        guard let roicAvg = getAverageROIC(companyCik: companyCik, facts: facts),
              let growthComposite = getCompositeGrowthRate(companyCik: companyCik, facts: facts) else {
            return nil
        }
        
        // Weight ROIC (60%) and growth (40%)
        let roicScore = min(max(roicAvg, 0), 30) * 2 // Cap at 30% ROIC for 60 points
        let growthScore = min(max(growthComposite, 0), 25) * 1.6 // Cap at 25% growth for 40 points
        
        return roicScore + growthScore
    }
    
    // MARK: - Free Cash Flow Consistency
    
    /// Calculate FCF consistency score (0-100)
    /// Measures how consistent free cash flow generation is over time
    func calculateFCFConsistencyScore(companyCik: Int, facts: CompanyFacts) -> Double? {
        let readyYears = freeCashFlowManager.freeCashFlowReadyYears(companyCik: companyCik, facts: facts)
        if readyYears.count < 3 { return nil }
        
        let fcfValues = readyYears.compactMap { year in
            freeCashFlowManager.calculateFreeCashFlowForYear(companyCik: companyCik, year: year, facts: facts)
        }
        
        if fcfValues.count < 3 { return nil }
        
        // Calculate mean and standard deviation
        let mean = fcfValues.reduce(0, +) / Double(fcfValues.count)
        let sumOfSquaredDifferences = fcfValues.map { pow($0 - mean, 2) }.reduce(0, +)
        let standardDeviation = sqrt(sumOfSquaredDifferences / Double(fcfValues.count))
        
        // Calculate coefficient of variation (lower is better for consistency)
        let coefficientOfVariation = standardDeviation / abs(mean)
        
        // Convert to score (0-100)
        // A CV of 0 would get 100, a CV of 1 would get 0
        let score = max(0, min(100, 100 * (1 - coefficientOfVariation)))
        
        // Add a bonus for positive FCF
        let positiveYearsPercentage = Double(fcfValues.filter { $0 > 0 }.count) / Double(fcfValues.count)
        let bonusForPositiveFCF = 20 * positiveYearsPercentage
        
        return min(100, score + bonusForPositiveFCF)
    }
    
    // MARK: - PEG Ratio (Price/Earnings to Growth)
    
    /// Calculate PEG Ratio: P/E divided by EPS Growth Rate
    /// Lower is generally better (<1 often considered good value)
    func calculatePEGRatio(companyCik: Int, facts: CompanyFacts, currentPE: Double) -> Double? {
        guard let epsGrowth = epsGrowthManager.calculateEPSGrowth(companyCik: companyCik, period: 5, facts: facts) else {
            return nil
        }
        
        // Avoid division by zero or negative growth
        if epsGrowth <= 0 { return nil }
        
        // Convert growth to percentage for conventional PEG ratio
        return currentPE / (epsGrowth * 100)
    }
    
    // MARK: - Rule of 40
    
    /// Calculate Rule of 40 score (growth rate + profit margin)
    /// Above 40 is considered good for software companies
    func calculateRuleOf40(companyCik: Int, facts: CompanyFacts) -> Double? {
        guard let salesGrowth = salesGrowthManager.calculateSalesGrowth(companyCik: companyCik, period: 1, facts: facts),
              let latestYear = salesGrowthManager.salesGrowthReadyYears(companyCik: companyCik, facts: facts).first,
              let revenue = salesGrowthManager.getMetricValue(companyCik: companyCik, year: latestYear, key: "Revenues", facts: facts),
              let netIncome = roicManager.getMetricValue(companyCik: companyCik, year: latestYear, key: "NetIncomeLoss", facts: facts),
              revenue > 0 else {
            return nil
        }
        
        let profitMargin = (netIncome / revenue) * 100
        let growthPercentage = salesGrowth * 100
        
        return growthPercentage + profitMargin
    }
    
    // MARK: - Financial Strength Score
    
    /// Calculate Financial Strength Score (0-100)
    /// Combines multiple metrics into a holistic view of financial health
    func calculateFinancialStrengthScore(companyCik: Int, facts: CompanyFacts) -> Double? {
        var scoreComponents: [Double] = []
        var totalWeight = 0.0
        
        // ROIC component (weight: 30%)
        if let roic = getAverageROIC(companyCik: companyCik, facts: facts) {
            let roicScore = min(max(roic * 100, 0), 30) / 30 * 100
            scoreComponents.append(roicScore * 0.3)
            totalWeight += 0.3
        }
        
        // Growth component (weight: 25%)
        if let growth = getCompositeGrowthRate(companyCik: companyCik, facts: facts) {
            let growthScore = min(max(growth * 100, 0), 30) / 30 * 100
            scoreComponents.append(growthScore * 0.25)
            totalWeight += 0.25
        }
        
        // FCF Consistency component (weight: 20%)
        if let fcfConsistency = calculateFCFConsistencyScore(companyCik: companyCik, facts: facts) {
            scoreComponents.append(fcfConsistency * 0.2)
            totalWeight += 0.2
        }
        
        // Balance Sheet Strength component (weight: 25%)
        // This requires additional metrics like debt/equity ratio
        if let equityGrowth = equityGrowthManager.calculateEquityGrowth(companyCik: companyCik, period: 5, facts: facts) {
            let equityGrowthScore = min(max(equityGrowth * 100, 0), 25) / 25 * 100
            scoreComponents.append(equityGrowthScore * 0.25)
            totalWeight += 0.25
        }
        
        // Must have at least 50% of components to calculate a valid score
        if totalWeight < 0.5 { return nil }
        
        // Normalize score based on available components
        let totalScore = scoreComponents.reduce(0, +) / totalWeight
        return min(100, max(0, totalScore))
    }
    
    // MARK: - Helper Methods
    
    private func getAverageROIC(companyCik: Int, facts: CompanyFacts) -> Double? {
        // Try to get 5-year average, fall back to 3-year if not available
        if let roic5yr = roicManager.calculateROICAverages(companyCik: companyCik, facts: facts, periods: [5])[5] {
            return roic5yr / 100 // Convert from percentage
        } else if let roic3yr = roicManager.calculateROICAverages(companyCik: companyCik, facts: facts, periods: [3])[3] {
            return roic3yr / 100
        }
        return nil
    }
    
    private func getCompositeGrowthRate(companyCik: Int, facts: CompanyFacts) -> Double? {
        var growthRates: [Double] = []
        
        // EPS Growth (weight: 35%)
        if let epsGrowth = epsGrowthManager.calculateEPSGrowth(companyCik: companyCik, period: 5, facts: facts) {
            growthRates.append(epsGrowth * 0.35)
        }
        
        // Sales Growth (weight: 30%)
        if let salesGrowth = salesGrowthManager.calculateSalesGrowth(companyCik: companyCik, period: 5, facts: facts) {
            growthRates.append(salesGrowth * 0.3)
        }
        
        // Equity Growth (weight: 20%)
        if let equityGrowth = equityGrowthManager.calculateEquityGrowth(companyCik: companyCik, period: 5, facts: facts) {
            growthRates.append(equityGrowth * 0.2)
        }
        
        // FCF Growth (weight: 15%)
        if let fcfGrowth = freeCashFlowManager.calculateFreeCashFlowGrowth(companyCik: companyCik, period: 5, facts: facts) {
            growthRates.append(fcfGrowth * 0.15)
        }
        
        // Need at least 2 growth rates to calculate composite
        if growthRates.isEmpty { return nil }
        
        return growthRates.reduce(0, +)
    }
}
