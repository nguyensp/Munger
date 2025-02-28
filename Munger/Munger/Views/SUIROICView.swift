//
//  SUIROICView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/27/25.
//

import SwiftUI

struct SUIROICView: View {
    let facts: CompanyFacts
    @EnvironmentObject var roicManager: ROICManager
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    @State private var roicReadyYears: [Int] = []
    @State private var hasGatheredROIC = false
    @State private var roicResults: [Int: Double] = [:] // Year -> ROIC
    @State private var roicAverageResults: [Int: Double] = [:] // Period (years) -> ROIC Average
    @State private var showingClearConfirmation = false

    private let roicMetricKeys = Set(["NetIncomeLoss", "Assets", "LiabilitiesCurrent"])
    private let periods = [10, 7, 5, 3, 1]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("ROIC")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    roicManager.gatherROICMetrics(companyCik: facts.cik, facts: facts)
                    roicReadyYears = roicManager.roicReadyYears(companyCik: facts.cik, facts: facts)
                    hasGatheredROIC = true
                    roicResults = [:]
                    roicAverageResults = [:]
                }) {
                    Text("Gather ROIC Data")
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
                .disabled(roicManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true)
            }

            Text("Return On Investment Capital: Net Income / (Total Assets - Current Liabilities)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)

            if let watched = roicManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                SavedMetricsSection(metricYears: watched, manager: roicManager)
            } else if hasGatheredROIC {
                Text("No ROIC metrics available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if hasGatheredROIC && !roicReadyYears.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("ROIC Calculation Ready For:")
                        .font(.headline)
                    ForEach(roicReadyYears, id: \.self) { year in
                        Button(action: {
                            if let roic = roicManager.calculateROICForYear(
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
                                    .foregroundColor(.blue)
                                Spacer()
                                if let roic = roicResults[year] {
                                    Text(String(format: "%.2f%%", roic * 100))
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
            }

            if hasGatheredROIC {
                let availableYears = roicManager.roicReadyYears(companyCik: facts.cik, facts: facts)
                let yearsCount = availableYears.count
                let validPeriods = periods.filter { $0 <= yearsCount }
                
                if !validPeriods.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("ROIC Averages")
                            .font(.headline)
                        ForEach(validPeriods, id: \.self) { period in
                            Button(action: {
                                if let roicAvg = roicManager.calculateROICAverages(
                                    companyCik: facts.cik,
                                    facts: facts,
                                    periods: [period]
                                )[period] {
                                    var updatedAverages = roicAverageResults
                                    updatedAverages[period] = roicAvg
                                    roicAverageResults = updatedAverages
                                }
                            }) {
                                HStack {
                                    Text("\(period) Years")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    if let roicAvg = roicAverageResults[period] {
                                        Text(String(format: "%.1f%%", roicAvg))
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
                    Text("Not enough data for ROIC averages (need at least 1 year)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 15)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            print("ROIC Metrics for CIK \(facts.cik):")
            if let watched = roicManager.watchedMetricYears[String(facts.cik)] {
                for metric in watched {
                    print("- \(metric.metricKey) (\(metric.year))")
                }
            }
            print("User Metrics for CIK \(facts.cik):")
            if let watched = userMetricsManager.watchedMetricYears[String(facts.cik)] {
                for metric in watched {
                    print("- \(metric.metricKey) (\(metric.year))")
                }
            }
        }
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Saved ROIC Metrics"),
                message: Text("Are you sure you want to clear all saved ROIC metrics for this company?"),
                primaryButton: .destructive(Text("Clear")) {
                    roicManager.clearMetrics(companyCik: facts.cik)
                    roicReadyYears = []
                    hasGatheredROIC = false
                    roicResults = [:]
                    roicAverageResults = [:]
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func SavedMetricsSection<T: MetricYearProtocol>(metricYears: Set<T>, manager: BaseMetricManager<T>) -> some View {
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
                                    UnitSectionView<T>(
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
    
    private func formatYear(_ year: Int) -> String {
        String(year)
    }
}
