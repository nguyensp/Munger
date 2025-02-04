//
//  SUICompanyFinancialsView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import SwiftUI

struct SUICompanyFinancialsView: View {
    @StateObject var viewModel = CompanyFinancialsViewModel()
    let company: Company
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.bigFiveMetrics.isEmpty {
                    BigFiveMetricsView(metrics: viewModel.bigFiveMetrics)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .padding()
        }
        .navigationTitle("\(company.companyName) Analysis")
        .onAppear {
            viewModel.fetchCompanyFinancials(cik: company.cik)
        }
    }
}

struct BigFiveMetricsView: View {
    let metrics: [BigFiveMetrics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Big Five Numbers")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(metrics, id: \.year) { yearly in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(yearly.year))
                                .font(.headline)
                            
                            MetricRow(label: "ROIC", value: yearly.roic)
                            MetricRow(label: "Sales Growth", value: yearly.salesGrowth)
                            MetricRow(label: "EPS Growth", value: yearly.epsGrowth)
                            MetricRow(label: "Equity Growth", value: yearly.equityGrowth)
                            MetricRow(label: "FCF Growth", value: yearly.fcfGrowth)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(width: 200)
                    }
                }
            }
            
            if metrics.count >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average Growth Rates")
                        .font(.headline)
                    
                    let roicAvg = metrics.map(\.roic).average()
                    let salesAvg = metrics.compactMap(\.salesGrowth).average()
                    let epsAvg = metrics.compactMap(\.epsGrowth).average()
                    let equityAvg = metrics.compactMap(\.equityGrowth).average()
                    let fcfAvg = metrics.compactMap(\.fcfGrowth).average()
                    
                    Group {
                        MetricRow(label: "ROIC", value: roicAvg)
                        MetricRow(label: "Sales Growth", value: salesAvg)
                        MetricRow(label: "EPS Growth", value: epsAvg)
                        MetricRow(label: "Equity Growth", value: equityAvg)
                        MetricRow(label: "FCF Growth", value: fcfAvg)
                    }
                }
                .padding(.top)
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
