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
    @State private var selectedView = ViewType.annual
    let company: Company
    let coordinator: AppCoordinator
    
    enum ViewType {
        case annual
        case raw
    }
    
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
                    Picker("View Type", selection: $selectedView) {
                        Text("By Year").tag(ViewType.annual)
                        Text("By Metric").tag(ViewType.raw)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    switch selectedView {
                    case .annual:
                        SUIAnnualDataView(facts: facts)
                    case .raw:
                        SUIFullRawDataView(facts: facts)
                    }
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
