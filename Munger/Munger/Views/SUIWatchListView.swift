//
//  SUIWatchListView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import SwiftUI

struct SUIWatchListView: View {
    @ObservedObject var viewModel: WatchListViewModel
    @EnvironmentObject var watchListManager: WatchListManager
    private let coordinator: AppCoordinator  // Add coordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.viewModel = coordinator.watchListViewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.watchedCompanies.isEmpty {
                    EmptyWatchListView()
                } else {
                    WatchList(
                        companies: viewModel.filteredCompanies,
                        onRemove: viewModel.removeFromWatchList,
                        coordinator: coordinator
                    )
                }
            }
            .navigationTitle("Watch List")
            .searchable(text: $viewModel.searchText, prompt: "Search Watch List")
            .overlay {
                if viewModel.filteredCompanies.isEmpty && !viewModel.searchText.isEmpty {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    } else {
                        EmptySearchView(searchText: viewModel.searchText)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadWatchedCompanies()
        }
    }
}

private struct WatchList: View {
    let companies: [Company]
    let onRemove: (Company) -> Void
    let coordinator: AppCoordinator
    
    var body: some View {
        List {
            ForEach(companies, id: \.id) { company in
                NavigationLink(destination: SUICompanyFinancialsView(company: company, coordinator: coordinator)) {
                    CompanyCellView(company: company)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        onRemove(company)
                    } label: {
                        Label("Remove", systemImage: "eye.fill")
                    }
                }
            }
        }
    }
}

private struct EmptyWatchListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Watched Companies")
                .font(.headline)
            Text("Add companies to your watch list to see them here")
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
    return SUIWatchListView(coordinator: coordinator)
        .environmentObject(coordinator.watchListManager)
}
