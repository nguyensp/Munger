//
//  SUIEquityGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUIEquityGrowthView: View {
    let facts: CompanyFacts
    @EnvironmentObject var equityGrowthManager: EquityGrowthManager
    @State private var equityGrowthReadyYears: [Int] = []
    @State private var hasGatheredEquityGrowth = false
    @State private var equityGrowthResults: [Int: Double] = [:]
    
    private let periods = [10, 7, 5, 3, 1]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Equity Growth Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    equityGrowthManager.gatherEquityGrowthMetrics(companyCik: facts.cik, facts: facts)
                    equityGrowthReadyYears = equityGrowthManager.equityGrowthReadyYears(companyCik: facts.cik, facts: facts)
                    hasGatheredEquityGrowth = true
                    equityGrowthResults = [:]
                }) {
                    Text("Gather Equity Data")
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Add formula description
            Text("Formula: CAGR of Stockholders' Equity over the selected period")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            if let watched = equityGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                Text("Equity data gathered for \(watched.count) data points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Growth rate calculations for different periods
            if hasGatheredEquityGrowth && !equityGrowthReadyYears.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Equity Growth Calculations")
                        .font(.headline)
                    ForEach(periods.filter { $0 <= equityGrowthReadyYears.count }, id: \.self) { period in
                        Button(action: {
                            if let growth = equityGrowthManager.calculateEquityGrowth(companyCik: facts.cik, period: period, facts: facts) {
                                equityGrowthResults[period] = growth * 100 // Convert to percentage
                            }
                        }) {
                            HStack {
                                Text("\(period) Year\(period > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                if let growth = equityGrowthResults[period] {
                                    Text(String(format: "%.2f%%", growth))
                                        .font(.subheadline)
                                        .foregroundColor(growth >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 15)
            } else if hasGatheredEquityGrowth {
                Text("Not enough data for equity growth calculations (need at least 2 years)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Add explanation
            if hasGatheredEquityGrowth {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Equity Growth")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("Equity Growth tracks the increase in a company's book value (assets minus liabilities). It reflects the company's ability to build intrinsic value through retained earnings and other equity-enhancing activities. Strong equity growth often indicates sustainable financial health and quality earnings.")
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
