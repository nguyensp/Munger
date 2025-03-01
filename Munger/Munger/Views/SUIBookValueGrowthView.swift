//
//  SUIBookValueGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 3/1/25.
//

import SwiftUI

struct SUIBookValueGrowthView: View {
    @EnvironmentObject var bookValueGrowthManager: BookValueGrowthManager
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    
    let facts: CompanyFacts
    
    @State private var bookValueReadyYears: [Int] = []
    @State private var hasGatheredBookValue = false
    @State private var bookValueGrowthResults: [Int: Double] = [:]
    @State private var bookValueGrowthAverageResults: [Int: Double] = [:]
    @State private var showingClearConfirmation = false
    
    private let periods = [10, 7, 5, 3, 1]
    
    var body: some View {
        ScrollView { // Added ScrollView
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Book Value Growth")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        bookValueGrowthManager.gatherBookValueMetrics(companyCik: facts.cik, facts: facts)
                        bookValueReadyYears = bookValueGrowthManager.bookValueReadyYears(companyCik: facts.cik, facts: facts)
                        hasGatheredBookValue = true
                        bookValueGrowthResults = [:]
                        bookValueGrowthAverageResults = [:]
                    }) {
                        Text("Gather BV Data")
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
                    .disabled(bookValueGrowthManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true)
                }
                
                Text("Book Value Growth: ((Equity_end - Equity_start) / Equity_start) * 100")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                if let watched = bookValueGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    SavedMetricsSection(metricYears: watched, manager: bookValueGrowthManager)
                } else if hasGatheredBookValue {
                    Text("No Book Value metrics available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if hasGatheredBookValue && !bookValueReadyYears.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Book Value Growth Calculation Ready For:")
                            .font(.headline)
                        ForEach(bookValueReadyYears.dropLast(), id: \.self) { startYear in
                            if let endYear = bookValueReadyYears.first(where: { $0 > startYear }) {
                                Button(action: {
                                    if let growth = bookValueGrowthManager.calculateBookValueGrowthForYears(companyCik: facts.cik, startYear: startYear, endYear: endYear, facts: facts) {
                                        var updatedResults = bookValueGrowthResults
                                        updatedResults[startYear] = growth
                                        bookValueGrowthResults = updatedResults
                                    }
                                }) {
                                    HStack {
                                        Text("\(startYear) to \(endYear)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let growth = bookValueGrowthResults[startYear] {
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
                
                if hasGatheredBookValue {
                    let availableYears = bookValueGrowthManager.bookValueReadyYears(companyCik: facts.cik, facts: facts)
                    let validPeriods = periods.filter { $0 < availableYears.count }
                    
                    if !validPeriods.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Book Value Growth Averages")
                                .font(.headline)
                            ForEach(validPeriods, id: \.self) { period in
                                Button(action: {
                                    let averages = bookValueGrowthManager.calculateBookValueGrowthAverages(companyCik: facts.cik, facts: facts, periods: [period])
                                    if let avg = averages[period] {
                                        var updatedAverages = bookValueGrowthAverageResults
                                        updatedAverages[period] = avg
                                        bookValueGrowthAverageResults = updatedAverages
                                    }
                                }) {
                                    HStack {
                                        Text("\(period) Years")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        if let avg = bookValueGrowthAverageResults[period] {
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
                        Text("Not enough data for Book Value growth averages (need at least 2 years)")
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
        .navigationTitle("Book Value Growth Analysis") // Optional: standalone title
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Saved Book Value Metrics"),
                message: Text("Are you sure you want to clear all saved Book Value metrics?"),
                primaryButton: .destructive(Text("Clear")) {
                    bookValueGrowthManager.clearMetrics(companyCik: facts.cik)
                    bookValueReadyYears = []
                    hasGatheredBookValue = false
                    bookValueGrowthResults = [:]
                    bookValueGrowthAverageResults = [:]
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func SavedMetricsSection(metricYears: Set<BookValueMetricYear>, manager: BookValueGrowthManager) -> some View {
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
                                    UnitSectionView<BookValueMetricYear>(
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
