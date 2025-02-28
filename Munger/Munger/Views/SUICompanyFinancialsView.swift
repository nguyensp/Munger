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
        case saved
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
                        Text("Saved").tag(ViewType.saved)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    switch selectedView {
                    case .annual:
                        SUIAnnualDataView(facts: facts)
                    case .raw:
                        SUIFullRawDataView(facts: facts)
                    case .saved:
                        SUISavedMetricsView(facts: facts)
                            .environmentObject(coordinator.epsGrowthManager)
                            .environmentObject(coordinator.epsGrowthManager)
                            .environmentObject(coordinator.salesGrowthManager)
                            .environmentObject(coordinator.equityGrowthManager)
                            .environmentObject(coordinator.freeCashFlowManager)
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
        .environmentObject(coordinator.roicManager) // Pass the manager
    }
}
