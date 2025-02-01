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
    
    private var cancellables = Set<AnyCancellable>()
    
    private let centralIndexKeyNetworkService: CentralIndexKeyNetworkService
    
    init(centralIndexKeyNetworkService: CentralIndexKeyNetworkService = CentralIndexKeyNetworkService()) {
        self.centralIndexKeyNetworkService = centralIndexKeyNetworkService
    }
    
    func fetchCompanies() {
        if isLoading == true {
            return
        }
        isLoading = true
        
        centralIndexKeyNetworkService.getCompanyTickers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
                self?.isLoading = true
            }, receiveValue: { [weak self] requestedCompanies in
                self?.companies = requestedCompanies
            })
            .store(in: &cancellables)
    }
}
