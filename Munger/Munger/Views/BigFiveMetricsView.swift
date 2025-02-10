//
//  BigFiveMetricsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import SwiftUI

struct BigFiveMetricsView: View {
    let metrics: [BigFiveMetrics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Big Five Numbers")
                .font(.title2)
                .fontWeight(.bold)
            
            if let latest = metrics.first {
                // Future Growth Rate Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Future Growth Rate")
                        .font(.headline)
                    
                    if let fgr = latest.estimatedFutureGrowthRate {
                        Text(String(format: "%.1f%%", fgr))
                            .font(.title3)
                            .foregroundColor(fgr >= 10 ? .green : .red)
                    } else {
                        Text("Insufficient historical data")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(metrics, id: \.year) { yearly in
                        YearlyMetricsCard(metrics: yearly)
                    }
                }
            }
            
            if let latest = metrics.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Historical Growth Rates")
                        .font(.headline)
                    
                    Group {
                        HistoricalMetricSection(label: "Sales Growth", rates: latest.salesGrowth)
                        HistoricalMetricSection(label: "EPS Growth", rates: latest.epsGrowth)
                        HistoricalMetricSection(label: "Equity Growth", rates: latest.equityGrowth)
                        HistoricalMetricSection(label: "FCF Growth", rates: latest.fcfGrowth)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct YearlyMetricsCard: View {
    let metrics: BigFiveMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(metrics.year))
                .font(.headline)
            
            MetricRow(label: "ROIC", value: metrics.roic)
            
            if let salesGrowth = metrics.salesGrowth?.average {
                MetricRow(label: "Sales Growth", value: salesGrowth)
            }
            if let epsGrowth = metrics.epsGrowth?.average {
                MetricRow(label: "EPS Growth", value: epsGrowth)
            }
            if let equityGrowth = metrics.equityGrowth?.average {
                MetricRow(label: "Equity Growth", value: equityGrowth)
            }
            if let fcfGrowth = metrics.fcfGrowth?.average {
                MetricRow(label: "FCF Growth", value: fcfGrowth)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .frame(width: 200)
    }
}

struct HistoricalMetricSection: View {
    let label: String
    let rates: HistoricalGrowthRates?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let rates = rates {
                HStack(spacing: 16) {
                    PeriodGrowthLabel("10Y", value: rates.tenYear)
                    PeriodGrowthLabel("7Y", value: rates.sevenYear)
                    PeriodGrowthLabel("5Y", value: rates.fiveYear)
                    PeriodGrowthLabel("3Y", value: rates.threeYear)
                }
                
                if let avg = rates.average {
                    MetricRow(label: "Average", value: avg)
                }
            } else {
                Text("Insufficient historical data")
                    .foregroundColor(.secondary)
            }
            
            Divider()
        }
    }
}

struct PeriodGrowthLabel: View {
    let period: String
    let value: Double?
    
    init(_ period: String, value: Double?) {
        self.period = period
        self.value = value
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(period)
                .font(.caption)
                .foregroundColor(.secondary)
            if let value = value {
                Text(String(format: "%.1f%%", value))
                    .font(.subheadline)
                    .foregroundColor(value >= 10 ? .green : .red)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: Double?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            if let value = value {
                Text(String(format: "%.1f%%", value))
                    .foregroundColor(value >= 10 ? .green : .red)
            } else {
                Text("N/A")
                    .foregroundColor(.gray)
            }
        }
    }
}
