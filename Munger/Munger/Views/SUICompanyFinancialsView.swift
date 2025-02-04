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
