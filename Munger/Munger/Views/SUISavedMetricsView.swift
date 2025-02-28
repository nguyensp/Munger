//
//  SUISavedMetricsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUISavedMetricsView: View {
    let facts: CompanyFacts
    @EnvironmentObject var userMetricsManager: UserMetricsManager
    @EnvironmentObject var roicManager: ROICManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // User Saved Metrics
                if let watched = userMetricsManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("User Saved Metrics")
                            .font(.title2)
                            .fontWeight(.bold)
                        SavedMetricsSection(metricYears: watched, manager: userMetricsManager)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // ROIC Section (now in its own view with updated name)
                //SUIROICView(facts: facts)

                // No metrics saved message
                if (userMetricsManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true) &&
                   (roicManager.watchedMetricYears[String(facts.cik)]?.isEmpty ?? true) {
                    Text("No metrics saved yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
            }
            .padding()
        }
    }

    // Generic SavedMetricsSection that works with any manager
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
}
