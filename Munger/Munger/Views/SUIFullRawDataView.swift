//
//  SUIFullRawDataView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/22/25.
//

import SwiftUI

struct SUIFullRawDataView: View {
    let facts: CompanyFacts
    @State private var searchText = ""
    // State to track expansion for each metric
    @State private var expandedMetrics: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Search bar
                TextField("Search metrics...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Financial Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Source: SEC EDGAR API (https://data.sec.gov/api/xbrl/companyfacts/CIK\(String(format: "%010d", facts.cik)).json)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Below is every metric retrieved for \(facts.entityName) from annual 10-K filings.")
                        .font(.subheadline)
                }
                .padding(.bottom, 10)

                // Metrics List
                if let usGaap = facts.facts.usGaap {
                    let filteredMetrics = usGaap.keys.filter {
                        searchText.isEmpty ||
                        $0.lowercased().contains(searchText.lowercased()) ||
                        (usGaap[$0]?.label?.lowercased().contains(searchText.lowercased()) ?? false)
                    }
                    ForEach(Array(filteredMetrics.sorted()), id: \.self) { metricKey in
                        if let metricData = usGaap[metricKey] {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedMetrics.contains(metricKey) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedMetrics.insert(metricKey)
                                        } else {
                                            expandedMetrics.remove(metricKey)
                                        }
                                    }
                                )
                            ) {
                                MetricFullSectionView(metricKey: metricKey, metricData: metricData)
                            } label: {
                                Text(metricData.label ?? metricKey)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                } else {
                    Text("No US-GAAP data available")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}

// Reusable view for each metric section
struct MetricFullSectionView: View {
    let metricKey: String
    let metricData: MetricData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Metric Header (use label if available, fallback to key)
            Text(metricData.label ?? metricKey)
                .font(.headline)
                .foregroundColor(.blue)
            if let description = metricData.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Units and Data Points
            ForEach(Array(metricData.units.keys.sorted()), id: \.self) { unit in
                if let dataPoints = metricData.units[unit]?.filter({ $0.isAnnual }) {
                    UnitSectionView(unit: unit, dataPoints: dataPoints)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Reusable view for each unit section within a metric
struct UnitSectionView: View {
    let unit: String
    let dataPoints: [DataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit: \(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Deduplicate data points by fiscal year, keeping the latest filing
            let uniqueDataPoints = deduplicateDataPoints(dataPoints)
            
            ForEach(uniqueDataPoints.indices, id: \.self) { index in
                let dataPoint = uniqueDataPoints[index]
                HStack {
                    Text("FY \(dataPoint.fy)")
                        .font(.subheadline)
                    Spacer()
                    Text(formatValue(dataPoint.val, unit: unit))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
                .background(index % 2 == 0 ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(4)
            }
            
            Text("Total Years: \(uniqueDataPoints.count) (\(yearRange(data: uniqueDataPoints)))")
                .font(.caption)
                .foregroundColor(uniqueDataPoints.count > 0 ? .green : .red)
        }
    }

    // Deduplicate data points by fiscal year, keeping the latest filing date
    private func deduplicateDataPoints(_ dataPoints: [DataPoint]) -> [DataPoint] {
        let groupedByYear = Dictionary(grouping: dataPoints, by: { $0.fy })
        return groupedByYear.values
            .map { points in
                points.sorted(by: { $0.filed > $1.filed }).first!
            }
            .sorted(by: { $0.fy > $1.fy }) // Sort by year, latest first
    }

    private func formatValue(_ value: Double, unit: String) -> String {
        switch unit.lowercased() {
        case "usd":
            if abs(value) >= 1_000_000_000 {
                return String(format: "$%.2fB", value / 1_000_000_000)
            } else if abs(value) >= 1_000_000 {
                return String(format: "$%.2fM", value / 1_000_000)
            } else {
                return String(format: "$%.2f", value)
            }
        case "pure":
            return String(format: "%.2f", value)
        case "shares":
            if abs(value) >= 1_000_000_000 {
                return String(format: "%.2fB", value / 1_000_000_000)
            } else if abs(value) >= 1_000_000 {
                return String(format: "%.2fM", value / 1_000_000)
            } else {
                return String(format: "%.0f", value)
            }
        default:
            return String(format: "%.2f", value) // Default for unknown units
        }
    }

    private func yearRange(data: [DataPoint]) -> String {
        guard !data.isEmpty else { return "None" }
        if let minYear = data.map({ $0.fy }).min(), let maxYear = data.map({ $0.fy }).max() {
            return "\(minYear)-\(maxYear)"
        }
        return "None"
    }
}
