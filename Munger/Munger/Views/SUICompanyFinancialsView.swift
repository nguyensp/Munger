//
//  SUICompanyFinancialsView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import SwiftUI
import Combine

struct SUICompanyFinancialsView: View {
    @StateObject private var viewModel: CompanyFinancialsViewModel
    let company: Company
    let coordinator: AppCoordinator
    
    init(company: Company, coordinator: AppCoordinator) {
        self.company = company
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: CompanyFinancialsViewModel(
            companyFinancialsNetworkService: coordinator.serviceFactory.makeCompanyFinancialsNetworkService()
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(destination: SUICompanyFilingsView(company: company, coordinator: coordinator)) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View SEC Filings")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if let facts = viewModel.companyFacts {
                    SUIFullRawDataView(facts: facts)
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
