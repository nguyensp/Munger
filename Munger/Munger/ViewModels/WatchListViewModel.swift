//
//  WatchListViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation
import Combine

class WatchListViewModel: ObservableObject {
    @Published var watchedCompanies: [Company] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let watchListManager: WatchListManager
    private let networkService: CentralIndexKeyNetworkService
    
    var filteredCompanies: [Company] {
        if searchText.isEmpty {
            return watchedCompanies
        } else {
            return watchedCompanies.filter { company in
                company.companyName.lowercased().contains(searchText.lowercased()) ||
                company.companyTicker.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    init(watchListManager: WatchListManager = WatchListManager(),
         networkService: CentralIndexKeyNetworkService = CentralIndexKeyNetworkService()) {
        self.watchListManager = watchListManager
        self.networkService = networkService
    }
    
    func loadWatchedCompanies() {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        networkService.getCompanyTickers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] companies in
                guard let self = self else { return }
                self.watchedCompanies = companies.filter { company in
                    self.watchListManager.isWatched(company: company)
                }
            })
            .store(in: &cancellables)
    }
    
    func removeFromWatchList(company: Company) {
        watchListManager.toggleWatch(company: company)
        watchedCompanies.removeAll { $0.cik == company.cik }
    }
}
