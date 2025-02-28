//
//  SUIFreeCashFlowView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI

struct SUIFreeCashFlowView: View {
    let facts: CompanyFacts
    @EnvironmentObject var freeCashFlowManager: FreeCashFlowManager
    @State private var fcfReadyYears: [Int] = []
    @State private var hasGatheredFCF = false
    @State private var fcfResults: [Int: Double] = [:]
    @State private var fcfGrowthResults: [Int: Double] = [:]
    
    private let periods = [10, 7, 5, 3, 1]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Free Cash Flow Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    freeCashFlowManager.gatherFreeCashFlowMetrics(companyCik: facts.cik, facts: facts)
                    fcfReadyYears = freeCashFlowManager.freeCashFlowReadyYears(companyCik: facts.cik, facts: facts)
                    hasGatheredFCF = true
                    fcfResults = [:]
                    fcfGrowthResults = [:]
                }) {
                    Text("Gather FCF Data")
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Add formula description
            Text("Formula: Operating Cash Flow - Capital Expenditures")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            if let watched = freeCashFlowManager.watchedMetricYears[String(facts.cik)], !watched.isEmpty {
                Text("Cash flow data gathered for \(watched.count) data points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Yearly FCF Calculations
            if hasGatheredFCF && !fcfReadyYears.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Free Cash Flow by Year")
                        .font(.headline)
                    ForEach(fcfReadyYears.prefix(5), id: \.self) { year in
                        Button(action: {
                            if let fcf = freeCashFlowManager.calculateFreeCashFlowForYear(companyCik: facts.cik, year: year, facts: facts) {
                                fcfResults[year] = fcf
                            }
                        }) {
                            HStack {
                                Text("\(year)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                if let fcf = fcfResults[year] {
                                    Text(formatCurrency(fcf))
                                        .font(.subheadline)
                                        .foregroundColor(fcf >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 15)
            } else if hasGatheredFCF {
                Text("No free cash flow data available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // FCF Growth Calculations
            if hasGatheredFCF && fcfReadyYears.count >= 2 {
                VStack(alignment: .leading, spacing: 15) {
                    Text("FCF Growth Rate")
                        .font(.headline)
                    ForEach(periods.filter { $0 <= fcfReadyYears.count }, id: \.self) { period in
                        Button(action: {
                            if let growth = freeCashFlowManager.calculateFreeCashFlowGrowth(companyCik: facts.cik, period: period, facts: facts) {
                                fcfGrowthResults[period] = growth * 100 // Convert to percentage
                            }
                        }) {
                            HStack {
                                Text("\(period) Year\(period > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                if let growth = fcfGrowthResults[period] {
                                    Text(String(format: "%.2f%%", growth))
                                        .font(.subheadline)
                                        .foregroundColor(growth >= 0 ? .green : .red)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 15)
            }
            
            // Add explanation
            if hasGatheredFCF {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Free Cash Flow")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("Free Cash Flow (FCF) represents the cash a company generates after accounting for operating expenses and capital expenditures. It shows the company's ability to generate cash that can be used for expansion, debt reduction, dividends, or share repurchases. Strong and consistent FCF is generally a positive indicator of financial health.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if abs(value) >= 1_000_000_000 {
            return String(format: "$%.2fB", value / 1_000_000_000)
        } else if abs(value) >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "$%.2fK", value / 1_000)
        } else {
            return String(format: "$%.2f", value)
        }
    }
}
