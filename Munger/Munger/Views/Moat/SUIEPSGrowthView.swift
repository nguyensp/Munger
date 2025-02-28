//
//  SUIEPSGrowthView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUIEPSGrowthView: View {
    let facts: CompanyFacts
    @EnvironmentObject var epsGrowthManager: EPSGrowthManager
    @State private var epsGrowthReadyYears: [Int] = []
    @State private var hasGatheredEPSGrowth = false
    @State private var epsGrowthResults: [Int: Double] = [:]
    
    private let periods = [10, 7, 5, 3, 1]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("EPS Growth Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    epsGrowthManager.gatherEPSGrowthMetrics(companyCik: facts.cik, facts: facts)
                    epsGrowthReadyYears = epsGrowthManager.epsGrowthReadyYears(companyCik: facts.cik, facts: facts)
                    hasGatheredEPSGrowth = true
                    epsGrowthResults = [:]
                }) {
                    Text("Gather EPS Growth Data")
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Add formula description
            Text("Formula: CAGR of Earnings Per Share over the selected period")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            if let watched = epsGrowthManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                Text("EPS data gathered for \(watched.count) data points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Growth rate calculations for different periods
            if hasGatheredEPSGrowth && !epsGrowthReadyYears.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("EPS Growth Calculations")
                        .font(.headline)
                    ForEach(periods.filter { $0 <= epsGrowthReadyYears.count }, id: \.self) { period in
                        Button(action: {
                            if let growth = epsGrowthManager.calculateEPSGrowth(companyCik: facts.cik, period: period, facts: facts) {
                                epsGrowthResults[period] = growth * 100 // Convert to percentage
                            }
                        }) {
                            HStack {
                                Text("\(period) Year\(period > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                if let growth = epsGrowthResults[period] {
                                    Text(String(format: "%.2f%%", growth))
                                        .font(.subheadline)
                                        .foregroundColor(growth >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 15)
            } else if hasGatheredEPSGrowth {
                Text("Not enough data for EPS growth calculations (need at least 2 years)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Add explanation
            if hasGatheredEPSGrowth {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About EPS Growth")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("Earnings Per Share (EPS) Growth measures how quickly a company's profitability per share is increasing. Higher EPS growth rates generally indicate that a company is expanding its ability to generate profit for each share of its stock.")
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
