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
                if let watched = metricsWatchListManager.watchedMetrics[String(facts.cik)], !watched.isEmpty {
                    ForEach(Array(watched.sorted()), id: \.self) { metricKey in
                        if let metricData = facts.facts.usGaap?[metricKey] {
                            DisclosureGroup {
                                MetricFullSectionView(metricKey: metricKey, metricData: metricData)
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
