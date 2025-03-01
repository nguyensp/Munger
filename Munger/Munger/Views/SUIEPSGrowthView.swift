//
//  SUIEPSGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import SwiftUI

struct SUIEPSGrowthView: View {
    @EnvironmentObject var epsGrowthManager: EPSGrowthManager
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    
    let facts: CompanyFacts
    
    @State private var epsReadyYears: [Int] = []
    @State private var hasGatheredEPS = false
    @State private var epsGrowthResults: [Int: Double] = [:]
    @State private var epsGrowthAverageResults: [Int: Double] = [:]
    @State private var showingClearConfirmation = false
    
    private let periods = [10, 7, 5, 3, 1]
    
    var body: some View {
        ScrollView { // Added ScrollView
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("EPS Growth")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        epsGrowthManager.gatherEPSMetrics(companyCik: facts.cik, facts: facts)
                        epsReadyYears = epsGrowthManager.epsReadyYears(companyCik: facts.cik, facts: facts)
                        hasGatheredEPS = true
                        epsGrowthResults = [:]
                        epsGrowthAverageResults = [:]
                    }) {
                        Text("Gather EPS Data")
                            .font(.headline)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Text("Clear Saved")
                            .font(.headline)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(epsGrowthManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true)
                }
                
                Text("Earnings Per Share Growth: ((EPS_end - EPS_start) / EPS_start) * 100")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                if let watched = epsGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    SavedMetricsSection(metricYears: watched, manager: epsGrowthManager)
                } else if hasGatheredEPS {
                    Text("No EPS metrics available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if hasGatheredEPS && !epsReadyYears.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("EPS Growth Calculation Ready For:")
                            .font(.headline)
                        ForEach(epsReadyYears.dropLast(), id: \.self) { startYear in
                            if let endYear = epsReadyYears.first(where: { $0 > startYear }) {
                                Button(action: {
                                    if let growth = epsGrowthManager.calculateEPSGrowthForYears(companyCik: facts.cik, startYear: startYear, endYear: endYear, facts: facts) {
                                        var updatedResults = epsGrowthResults
                                        updatedResults[startYear] = growth
                                        epsGrowthResults = updatedResults
                                    }
                                }) {
                                    HStack {
                                        Text("\(startYear) to \(endYear)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let growth = epsGrowthResults[startYear] {
                                            Text(String(format: "%.2f%%", growth))
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)
                }
                
                if hasGatheredEPS {
                    let availableYears = epsGrowthManager.epsReadyYears(companyCik: facts.cik, facts: facts)
                    let validPeriods = periods.filter { $0 < availableYears.count }
                    
                    if !validPeriods.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("EPS Growth Averages")
                                .font(.headline)
                            ForEach(validPeriods, id: \.self) { period in
                                Button(action: {
                                    let averages = epsGrowthManager.calculateEPSGrowthAverages(companyCik: facts.cik, facts: facts, periods: [period])
                                    if let avg = averages[period] {
                                        var updatedAverages = epsGrowthAverageResults
                                        updatedAverages[period] = avg
                                        epsGrowthAverageResults = updatedAverages
                                    }
                                }) {
                                    HStack {
                                        Text("\(period) Years")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let avg = epsGrowthAverageResults[period] {
                                            Text(String(format: "%.1f%%", avg))
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 15)
                    } else {
                        Text("Not enough data for EPS growth averages (need at least 2 years)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 15)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        } // End ScrollView
        .navigationTitle("EPS Growth Analysis") // Optional: standalone title
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Saved EPS Metrics"),
                message: Text("Are you sure you want to clear all saved EPS metrics for this company?"),
                primaryButton: .destructive(Text("Clear")) {
                    epsGrowthManager.clearMetrics(companyCik: facts.cik)
                    epsReadyYears = []
                    hasGatheredEPS = false
                    epsGrowthResults = [:]
                    epsGrowthAverageResults = [:]
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func SavedMetricsSection(metricYears: Set<EPSMetricYear>, manager: EPSGrowthManager) -> some View {
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
                                    UnitSectionView<EPSMetricYear>(
                                        unit: unit,
                                        dataPoints: filteredDataPoints,
                                        metricKey: metricKey,
                                        companyCik: facts.cik,
                                        manager: manager
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
                        .padding(.vertical, 8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
