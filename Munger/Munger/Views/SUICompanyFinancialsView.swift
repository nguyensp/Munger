//
//  SUICompanyFinancialsView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import SwiftUI
import Combine

struct SUICompanyFinancialsView: View {
    @EnvironmentObject private var viewModel: CompanyFinancialsViewModel
   
    @State private var selectedView = ViewType.annual
    let company: Company
    
    enum ViewType {
        case annual
        case raw
        case saved
        case calculate
    }
    
    init(company: Company) {
        self.company = company
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(destination: SUICompanyFilingsView(company: company)) {
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
                        Text("Calculate").tag(ViewType.calculate)
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
                    case .calculate:
                        SUIROICView(facts: facts)
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
