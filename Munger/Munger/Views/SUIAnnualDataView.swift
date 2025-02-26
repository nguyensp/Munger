//
//  SUIAnnualDataView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/22/25.
//

import SwiftUI

struct SUIAnnualDataView: View {
    let facts: CompanyFacts
    @State private var searchText = ""
    @State private var selectedYear: Int?
    @EnvironmentObject var metricsWatchListManager: MetricsWatchListManager // Add this
    
    private var years: [Int] {
        guard let usGaap = facts.facts.usGaap else { return [] }
        let allYears = usGaap.values.flatMap { metricData in
            metricData.units.values.flatMap { dataPoints in
                dataPoints.filter { $0.isAnnual }.map { $0.fy }
            }
        }
        return Array(Set(allYears)).sorted(by: >)
    }
    
    private func getMetricsForYear(_ year: Int) -> [(key: String, value: Double, unit: String, label: String)] {
        guard let usGaap = facts.facts.usGaap else { return [] }
        
        return usGaap.compactMap { (key, metricData) -> (String, Double, String, String)? in
            if !searchText.isEmpty {
                let label = metricData.label?.lowercased() ?? key.lowercased()
                guard label.contains(searchText.lowercased()) else { return nil }
            }
            
            let latestValue = metricData.units.compactMap { (unit, dataPoints) -> (Double, String)? in
                let yearPoints = dataPoints.filter { $0.isAnnual && $0.fy == year }
                guard let latest = yearPoints.sorted(by: { $0.filed > $1.filed }).first else { return nil }
                return (latest.val, unit)
            }.first
            
            guard let (value, unit) = latestValue else { return nil }
            return (key, value, unit, metricData.label ?? key)
        }
        .sorted { $0.label < $1.label }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Search metrics...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(years, id: \.self) { year in
                            Button(action: {
                                withAnimation {
                                    selectedYear = selectedYear == year ? nil : year
                                }
                            }) {
                                Text(" \(String(year))")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedYear == year ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedYear == year ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let selectedYear = selectedYear {
                    let metrics = getMetricsForYear(selectedYear)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fiscal Year \(String(selectedYear))")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(metrics, id: \.key) { metric in
                            HStack {
                                MetricRowView(
                                    label: metric.label,
                                    value: metric.value,
                                    unit: metric.unit
                                )
                                Spacer()
                                Button(action: {
                                    metricsWatchListManager.toggleMetric(companyCik: facts.cik, metricKey: metric.key)
                                }) {
                                    Image(systemName: metricsWatchListManager.isWatched(companyCik: facts.cik, metricKey: metric.key) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    Text("Select a year to view metrics")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
}

struct MetricRowView: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
            HStack {
                Text(formatValue(value, unit: unit))
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray5))
        .cornerRadius(8)
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
            return String(format: "%.2f", value)
        }
    }
}
