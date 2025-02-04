//
//  CompanyListViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation
import Combine

class CompanyListViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var isLoading: Bool = false
    @Published var userSearchText: String = ""
    @Published var error: Error?
    
    var filteredCompanies: [Company] {
        if userSearchText.isEmpty {
            return companies
        } else {
            return companies.filter {
                return rankCompany($0, userSearchText) > 0
            }.sorted {
                return rankCompany($0, userSearchText) > rankCompany($1, userSearchText)
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let centralIndexKeyNetworkService: CentralIndexKeyNetworkService
    
    init(centralIndexKeyNetworkService: CentralIndexKeyNetworkService = CentralIndexKeyNetworkService()) {
        self.centralIndexKeyNetworkService = centralIndexKeyNetworkService
    }
    
    func fetchCompanies() {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        centralIndexKeyNetworkService.getCompanyTickers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                    self?.companies = []
                }
            }, receiveValue: { [weak self] requestedCompanies in
                self?.companies = requestedCompanies
            })
            .store(in: &cancellables)
    }
    
    func rankCompany(_ company: Company, _ searchTerm: String) -> Int {
        let ticker = company.companyTicker.lowercased()
        let name = company.companyName.lowercased()
        let term = searchTerm.lowercased()
        
        if searchTerm.isEmpty {
            return 0
        }
        
        // Exact matches
        if ticker == term {
            return 5
        } else if name == term {
            return 4
        }
        
        // Prefix matches
        if ticker.hasPrefix(term) {
            return 3
        } else if name.hasPrefix(term) {
            return 2
        }
        
        // Contains matches
        if name.contains(term) || ticker.contains(term) {
            return 1
        }
        
        return 0
    }
}
