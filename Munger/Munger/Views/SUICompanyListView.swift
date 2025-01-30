//
//  SUICompanyListView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI

struct SUICompanyListView: View {
    @StateObject var viewModel = CompanyListViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.companies, id: \.id) { company in
                    CompanyCellView(company: company)
                }
            }
            .navigationTitle("Companies Available")
            .onAppear {
                viewModel.fetchCompanies()
            }
            .refreshable {
                viewModel.fetchCompanies()
            }
        }
    }
}

struct CompanyCellView: View {
    var company: Company
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(company.companyName)
                    .font(.headline)
                Text(company.companyTicker)
                    .font(.subheadline)
            }
            Spacer()
            VStack(alignment: .leading) {
                Text(String(company.cik))
                    .font(.subheadline)
                Text(company.companyExchange)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    SUICompanyListView()
}
