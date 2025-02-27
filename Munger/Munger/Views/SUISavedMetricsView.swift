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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let watched = metricsWatchListManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                    let groupedByMetric = Dictionary(grouping: watched, by: { $0.metricKey })
                    ForEach(groupedByMetric.keys.sorted(), id: \.self) { metricKey in
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
                } else {
                    Text("No metrics saved yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
}
