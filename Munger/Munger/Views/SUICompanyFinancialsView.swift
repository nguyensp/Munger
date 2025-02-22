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
    
    init(company: Company, serviceFactory: ServiceFactoryProtocol) {
        self.company = company
        _viewModel = StateObject(wrappedValue: CompanyFinancialsViewModel(
            companyFinancialsNetworkService: serviceFactory.makeCompanyFinancialsNetworkService()
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
