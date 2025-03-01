//
//  SUISalesGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import SwiftUI

struct SUISalesGrowthView: View {
    @EnvironmentObject var salesGrowthManager: SalesGrowthManager
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    
    let facts: CompanyFacts
    
    @State private var salesReadyYears: [Int] = []
    @State private var hasGatheredSales = false
    @State private var salesGrowthResults: [Int: Double] = [:]
    @State private var salesGrowthAverageResults: [Int: Double] = [:]
    @State private var showingClearConfirmation = false
    
    private let periods = [10, 7, 5, 3, 1]
    
    var body: some View {
        ScrollView { // Added ScrollView
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Sales Growth")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        salesGrowthManager.gatherSalesMetrics(companyCik: facts.cik, facts: facts)
                        salesReadyYears = salesGrowthManager.salesReadyYears(companyCik: facts.cik, facts: facts)
                        hasGatheredSales = true
                        salesGrowthResults = [:]
                        salesGrowthAverageResults = [:]
                    }) {
                        Text("Gather Sales Data")
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
                    .disabled(salesGrowthManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true)
                }
                
                Text("Sales Growth: ((Sales_end - Sales_start) / Sales_start) * 100")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                if let watched = salesGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    SavedMetricsSection(metricYears: watched, manager: salesGrowthManager)
                } else if hasGatheredSales {
                    Text("No Sales metrics available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if hasGatheredSales && !salesReadyYears.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sales Growth Calculation Ready For:")
                            .font(.headline)
                        ForEach(salesReadyYears.dropLast(), id: \.self) { startYear in
                            if let endYear = salesReadyYears.first(where: { $0 > startYear }) {
                                Button(action: {
                                    if let growth = salesGrowthManager.calculateSalesGrowthForYears(companyCik: facts.cik, startYear: startYear, endYear: endYear, facts: facts) {
                                        var updatedResults = salesGrowthResults
                                        updatedResults[startYear] = growth
                                        salesGrowthResults = updatedResults
                                    }
                                }) {
                                    HStack {
                                        Text("\(startYear) to \(endYear)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let growth = salesGrowthResults[startYear] {
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
                
                if hasGatheredSales {
                    let availableYears = salesGrowthManager.salesReadyYears(companyCik: facts.cik, facts: facts)
                    let validPeriods = periods.filter { $0 < availableYears.count }
                    
                    if !validPeriods.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Sales Growth Averages")
                                .font(.headline)
                            ForEach(validPeriods, id: \.self) { period in
                                Button(action: {
                                    let averages = salesGrowthManager.calculateSalesGrowthAverages(companyCik: facts.cik, facts: facts, periods: [period])
                                    if let avg = averages[period] {
                                        var updatedAverages = salesGrowthAverageResults
                                        updatedAverages[period] = avg
                                        salesGrowthAverageResults = updatedAverages
                                    }
                                }) {
                                    HStack {
                                        Text("\(period) Years")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let avg = salesGrowthAverageResults[period] {
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
                        Text("Not enough data for Sales growth averages (need at least 2 years)")
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
        .navigationTitle("Sales Growth Analysis") // Optional: standalone title
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Saved Sales Metrics"),
                message: Text("Are you sure you want to clear all saved Sales metrics for this company?"),
                primaryButton: .destructive(Text("Clear")) {
                    salesGrowthManager.clearMetrics(companyCik: facts.cik)
                    salesReadyYears = []
                    hasGatheredSales = false
                    salesGrowthResults = [:]
                    salesGrowthAverageResults = [:]
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func SavedMetricsSection(metricYears: Set<SalesMetricYear>, manager: SalesGrowthManager) -> some View {
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
                                    UnitSectionView<SalesMetricYear>(
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
