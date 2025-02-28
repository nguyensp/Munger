//
//  SUISavedMetricsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUISavedMetricsView: View {
    let facts: CompanyFacts
    @EnvironmentObject var roicManager: ROICManager
    @EnvironmentObject var epsGrowthManager: EPSGrowthManager
    @EnvironmentObject var salesGrowthManager: SalesGrowthManager
    @EnvironmentObject var equityGrowthManager: EquityGrowthManager
    @EnvironmentObject var freeCashFlowManager: FreeCashFlowManager
    
    // State variables for ROIC view
    @State private var roicReadyYears: [Int] = []
    @State private var hasGatheredROIC = false
    @State private var roicResults: [Int: Double] = [:]
    @State private var roicAverageResults: [Int: Double] = [:]
    
    // State variables for other metric views
    @State private var epsGrowthReadyYears: [Int] = []
    @State private var hasGatheredEPSGrowth = false
    @State private var epsGrowthResults: [Int: Double] = [:]
    
    @State private var salesGrowthReadyYears: [Int] = []
    @State private var hasGatheredSalesGrowth = false
    @State private var salesGrowthResults: [Int: Double] = [:]
    
    @State private var equityGrowthReadyYears: [Int] = []
    @State private var hasGatheredEquityGrowth = false
    @State private var equityGrowthResults: [Int: Double] = [:]
    
    @State private var fcfReadyYears: [Int] = []
    @State private var hasGatheredFCF = false
    @State private var fcfResults: [Int: Double] = [:]
    @State private var fcfGrowthResults: [Int: Double] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) { // Increased spacing for better readability
                // User Saved Metrics (from all managers)
                let allWatched = [
                    roicManager.watchedMetricYears[String(facts.cik)] ?? Set<ROICMetricYear>()
                    // Note: This is a simplified example. In reality, you'll need type conversion
                    // or a more sophisticated method to combine different metric types
                ]
                
                if !allUserSavedMetrics.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("User Saved Metrics")
                            .font(.title2)
                            .fontWeight(.bold)
                        ForEach(allUserSavedMetrics, id: \.self) { metric in
                            Text(metric)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12) // Slightly larger corner radius for softer edges
                }

                // ROIC View
                SUIROICView(facts: facts)
                    .padding(.bottom, 10)
                
                // EPS Growth View
                SUIEPSGrowthView(facts: facts)
                    .padding(.bottom, 10)
                
                // Sales Growth View
                SUISalesGrowthView(facts: facts)
                    .padding(.bottom, 10)
                
                // Equity Growth View
                SUIEquityGrowthView(facts: facts)
                    .padding(.bottom, 10)
                
                // Free Cash Flow View
                SUIFreeCashFlowView(facts: facts)
            }
            .padding()
        }
    }

    // List of unique metrics that the user has saved across all managers
    private var allUserSavedMetrics: [String] {
        var metrics: [String] = []
        
        // Add unique metrics from ROIC manager (excluding the ROIC calculation ones)
        let roicMetricKeys = Set(["NetIncomeLoss", "Assets", "LiabilitiesCurrent"])
        if let watched = roicManager.watchedMetricYears[String(facts.cik)] {
            for metricYear in watched {
                if !roicMetricKeys.contains(metricYear.metricKey) && !metrics.contains(metricYear.metricKey) {
                    metrics.append(metricYear.metricKey)
                }
            }
        }
        
        // Add metrics from other managers here if needed
        
        return metrics.sorted()
    }

    private func SavedMetricsSection(metricYears: Set<ROICMetricYear>) -> some View {
        let groupedByMetric = Dictionary(grouping: metricYears, by: { $0.metricKey })
        return ForEach(groupedByMetric.keys.sorted(), id: \.self) { metricKey in
            if let metricData = facts.facts.usGaap?[metricKey] {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        if let description = metricData.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        ForEach(Array(metricData.units.keys.sorted()), id: \.self) { unit in
                            if let dataPoints = metricData.units[unit]?.filter({ $0.isAnnual }) {
                                let savedYears = groupedByMetric[metricKey]?.map { $0.year } ?? []
                                let filteredDataPoints = dataPoints.filter { savedYears.contains($0.fy) }
                                if !filteredDataPoints.isEmpty {
                                    UnitSectionView(
                                        unit: unit,
                                        dataPoints: filteredDataPoints,
                                        metricKey: metricKey,
                                        companyCik: facts.cik
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } label: {
                    Text(metricData.label ?? metricKey)
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.vertical, 8) // Increased vertical padding
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
