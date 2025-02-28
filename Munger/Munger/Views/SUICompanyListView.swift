//
//  SUICompanyListView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI
import Combine

struct SUICompanyListView: View {
    @EnvironmentObject var viewModel: CompanyListViewModel
    @EnvironmentObject var watchListManager: WatchListManager
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ErrorView(message: error.localizedDescription)
            } else if viewModel.companies.isEmpty {
                EmptyStateView()
            } else {
                CompanyList(companies: viewModel.filteredCompanies)
            }
        }
        .navigationTitle("Companies Available")
        .searchable(text: $viewModel.userSearchText, prompt: "Search Companies")
        .overlay {
            if viewModel.filteredCompanies.isEmpty && !viewModel.userSearchText.isEmpty {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView.search(text: viewModel.userSearchText)
                } else {
                    EmptySearchView(searchText: viewModel.userSearchText)
                }
            }
        }
        .onAppear {
            viewModel.fetchCompanies()
        }
        .refreshable {
            viewModel.fetchCompanies()
        }
    }
}

struct CompanyList: View {
    let companies: [Company]
    
    var body: some View {
        List {
            ForEach(companies, id: \.id) { company in
                NavigationLink(destination: SUICompanyFinancialsView(company: company)) {
                    CompanyCellView(company: company)
                }
                .swipeActions(edge: .leading) {
                    SUIWatchListButton(company: company)
                        .tint(.yellow)
                }
            }
        }
    }
}


struct CompanyCellView: View {
    @EnvironmentObject var watchListManager: WatchListManager
    var company: Company
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(company.companyName)
                    .font(.headline)
                Text(company.companyTicker)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(company.cik))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(company.companyExchange)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            if watchListManager.isWatched(company: company) {
                Image(systemName: "eye.fill")
                    .foregroundColor(.yellow)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SUIWatchListButton: View {
    @EnvironmentObject var watchListManager: WatchListManager
    let company: Company
    
    var body: some View {
        Button {
            watchListManager.toggleWatch(company: company)
        } label: {
            Label("Watch", systemImage: watchListManager.isWatched(company: company) ? "eye.fill" : "eye")
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Companies Available")
                .font(.headline)
            Text("Pull to refresh to load companies")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No results for \"\(searchText)\"")
                .font(.headline)
            Text("Try searching for a different company or ticker")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    let factory = ServiceFactory()
    let coordinator = AppCoordinator(serviceFactory: factory)
    SUICompanyListView()
        .environmentObject(coordinator.companyListViewModel)
        .environmentObject(coordinator.watchListManager)
}
