//
//  SUISalesGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUISalesGrowthView: View {
    let facts: CompanyFacts
    @EnvironmentObject var salesGrowthManager: SalesGrowthManager
    @State private var salesGrowthReadyYears: [Int] = []
    @State private var hasGatheredSalesGrowth = false
    @State private var salesGrowthResults: [Int: Double] = [:]
    
    private let periods = [10, 7, 5, 3, 1]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Revenue Growth Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    salesGrowthManager.gatherSalesGrowthMetrics(companyCik: facts.cik, facts: facts)
                    salesGrowthReadyYears = salesGrowthManager.salesGrowthReadyYears(companyCik: facts.cik, facts: facts)
                    hasGatheredSalesGrowth = true
                    salesGrowthResults = [:]
                }) {
                    Text("Gather Revenue Data")
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Add formula description
            Text("Formula: CAGR of Revenue over the selected period")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            if let watched = salesGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                Text("Revenue data gathered for \(watched.count) data points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Growth rate calculations for different periods
            if hasGatheredSalesGrowth && !salesGrowthReadyYears.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Revenue Growth Calculations")
                        .font(.headline)
                    ForEach(periods.filter { $0 <= salesGrowthReadyYears.count }, id: \.self) { period in
                        Button(action: {
                            if let growth = salesGrowthManager.calculateSalesGrowth(companyCik: facts.cik, period: period, facts: facts) {
                                salesGrowthResults[period] = growth * 100 // Convert to percentage
                            }
                        }) {
                            HStack {
                                Text("\(period) Year\(period > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                if let growth = salesGrowthResults[period] {
                                    Text(String(format: "%.2f%%", growth))
                                        .font(.subheadline)
                                        .foregroundColor(growth >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 15)
            } else if hasGatheredSalesGrowth {
                Text("Not enough data for revenue growth calculations (need at least 2 years)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Add explanation
            if hasGatheredSalesGrowth {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Revenue Growth")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("Revenue Growth is a fundamental metric that measures a company's ability to increase its sales over time. Consistent revenue growth indicates strong market demand for a company's products or services and is often a prerequisite for long-term profitability.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
