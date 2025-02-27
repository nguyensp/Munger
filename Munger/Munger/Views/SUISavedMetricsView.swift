//
//  SUISavedMetricsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUISavedMetricsView: View {
    let facts: CompanyFacts
    @EnvironmentObject var metricsWatchListManager: MetricsWatchListManager
    @State private var roicReadyYears: [Int] = []
    @State private var hasGatheredROIC = false
    @State private var roicResults: [Int: Double] = [:] // Year -> ROIC

    private let roicMetricKeys = Set(["NetIncomeLoss", "Assets", "LiabilitiesCurrent"])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // User Saved Metrics
                if let watched = metricsWatchListManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    let userWatched = watched.filter { !roicMetricKeys.contains($0.metricKey) }
                    if !userWatched.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("User Saved Metrics")
                                .font(.title2)
                                .fontWeight(.bold)
                            SavedMetricsSection(metricYears: userWatched)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                // ROIC Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ROIC Metrics")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            metricsWatchListManager.gatherROICMetrics(companyCik: facts.cik, facts: facts)
                            roicReadyYears = metricsWatchListManager.roicReadyYears(companyCik: facts.cik, facts: facts)
                            hasGatheredROIC = true
                            roicResults = [:] // Reset results when gathering anew
                        }) {
                            Text("Gather ROIC Data")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }

                    if let watched = metricsWatchListManager.watchedMetricYears[String(facts.cik)] {
                        let roicWatched = watched.filter { roicMetricKeys.contains($0.metricKey) }
                        if !roicWatched.isEmpty {
                            SavedMetricsSection(metricYears: roicWatched)
                        } else if hasGatheredROIC {
                            Text("No ROIC metrics available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    if !roicReadyYears.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ROIC Calculation Ready For:")
                                .font(.headline)
                            ForEach(roicReadyYears, id: \.self) { year in
                                Button(action: {
                                    if let roic = metricsWatchListManager.calculateROICForYear(
                                        companyCik: facts.cik,
                                        year: year,
                                        facts: facts
                                    ) {
                                        var updatedResults = roicResults
                                        updatedResults[year] = roic
                                        roicResults = updatedResults
                                    }
                                }) {
                                    HStack {
                                        Text("\(formatYear(year))")
                                            .font(.subheadline)
                                        Spacer()
                                        if let roic = roicResults[year] {
                                            Text(String(format: "%.2f%%", roic * 100))
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                if metricsWatchListManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true {
                    Text("No metrics saved yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }

    private func SavedMetricsSection(metricYears: Set<MetricsWatchListManager.MetricYear>) -> some View {
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
                        .padding(.vertical, 4)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // Format fiscal year to remove commas (e.g., "2,024" -> "2024")
    private func formatYear(_ year: Int) -> String {
        String(year) // Simply converts the Int to a String, removing any formatting like commas
    }
}
