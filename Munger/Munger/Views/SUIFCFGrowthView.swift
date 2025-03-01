//
//  SUIFCFGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import SwiftUI

struct SUIFCFGrowthView: View {
    @EnvironmentObject var fcfGrowthManager: FCFGrowthManager
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    
    let facts: CompanyFacts
    
    @State private var fcfReadyYears: [Int] = []
    @State private var hasGatheredFCF = false
    @State private var fcfGrowthResults: [Int: Double] = [:]
    @State private var fcfGrowthAverageResults: [Int: Double] = [:]
    @State private var showingClearConfirmation = false
    
    private let periods = [10, 7, 5, 3, 1]
    
    var body: some View {
        ScrollView { // Added ScrollView
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("FCF Growth")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        fcfGrowthManager.gatherFCFMetrics(companyCik: facts.cik, facts: facts)
                        fcfReadyYears = fcfGrowthManager.fcfReadyYears(companyCik: facts.cik, facts: facts)
                        hasGatheredFCF = true
                        fcfGrowthResults = [:]
                        fcfGrowthAverageResults = [:]
                    }) {
                        Text("Gather FCF Data")
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
                    .disabled(fcfGrowthManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true)
                }
                
                Text("Free Cash Flow Growth: ((FCF_end - FCF_start) / FCF_start) * 100, FCF = Operating Cash - CapEx")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                if let watched = fcfGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    SavedMetricsSection(metricYears: watched, manager: fcfGrowthManager)
                } else if hasGatheredFCF {
                    Text("No FCF metrics available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if hasGatheredFCF && !fcfReadyYears.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("FCF Growth Calculation Ready For:")
                            .font(.headline)
                        ForEach(fcfReadyYears.dropLast(), id: \.self) { startYear in
                            if let endYear = fcfReadyYears.first(where: { $0 > startYear }) {
                                Button(action: {
                                    if let growth = fcfGrowthManager.calculateFCFGrowthForYears(companyCik: facts.cik, startYear: startYear, endYear: endYear, facts: facts) {
                                        var updatedResults = fcfGrowthResults
                                        updatedResults[startYear] = growth
                                        fcfGrowthResults = updatedResults
                                    }
                                }) {
                                    HStack {
                                        Text("\(startYear) to \(endYear)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let growth = fcfGrowthResults[startYear] {
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
                
                if hasGatheredFCF {
                    let availableYears = fcfGrowthManager.fcfReadyYears(companyCik: facts.cik, facts: facts)
                    let validPeriods = periods.filter { $0 < availableYears.count }
                    
                    if !validPeriods.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("FCF Growth Averages")
                                .font(.headline)
                            ForEach(validPeriods, id: \.self) { period in
                                Button(action: {
                                    let averages = fcfGrowthManager.calculateFCFGrowthAverages(companyCik: facts.cik, facts: facts, periods: [period])
                                    if let avg = averages[period] {
                                        var updatedAverages = fcfGrowthAverageResults
                                        updatedAverages[period] = avg
                                        fcfGrowthAverageResults = updatedAverages
                                    }
                                }) {
                                    HStack {
                                        Text("\(period) Years")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let avg = fcfGrowthAverageResults[period] {
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
                        Text("Not enough data for FCF growth averages (need at least 2 years)")
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
        .navigationTitle("FCF Growth Analysis") // Optional: standalone title
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Saved FCF Metrics"),
                message: Text("Are you sure you want to clear all saved FCF metrics?"),
                primaryButton: .destructive(Text("Clear")) {
                    fcfGrowthManager.clearMetrics(companyCik: facts.cik)
                    fcfReadyYears = []
                    hasGatheredFCF = false
                    fcfGrowthResults = [:]
                    fcfGrowthAverageResults = [:]
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func SavedMetricsSection(metricYears: Set<FCFMetricYear>, manager: FCFGrowthManager) -> some View {
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
                                    UnitSectionView<FCFMetricYear>(
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
