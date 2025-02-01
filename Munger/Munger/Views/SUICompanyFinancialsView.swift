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
        VStack {
            Text(company.companyName)
                .font(.title)
            Text(String(company.cik))
            Text(viewModel.companyFacts?.facts.usGaap.description ?? "Loading")
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Financials")
        .onAppear {
            viewModel.fetchCompanyFinancials(cik: company.cik)
        }
        .refreshable {
            viewModel.fetchCompanyFinancials(cik: company.cik)
        }
    }
}

