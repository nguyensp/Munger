//
//  CompanyFinancialsViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//
/*
import Foundation
import Combine

class CompanyFinancialsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var companyFacts: CompanyFacts?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let companyFinancialsNetworkService: CompanyFinancialsNetworkService
    
    init(companyFinancialsNetworkService: CompanyFinancialsNetworkService = CompanyFinancialsNetworkService()) {
        self.companyFinancialsNetworkService = companyFinancialsNetworkService
    }
    
    func fetchCompanyFinancials(cik: Int) {
        if isLoading == true {
            return
        }
        
        isLoading = true
        error = nil
        
        companyFinancialsNetworkService.getCompanyFinancials(cik: cik)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                    print(error)
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] facts in
                self?.companyFacts = facts
                print("Company Facts Receive Value: \(facts)")
            })
            .store(in: &cancellables)
    }
}
*/

import Foundation
import Combine

class CompanyFinancialsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var companyFacts: CompanyFacts?
    @Published var bigFiveMetrics: [BigFiveMetrics] = []
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let companyFinancialsNetworkService: CompanyFinancialsNetworkService
    
    init(companyFinancialsNetworkService: CompanyFinancialsNetworkService = CompanyFinancialsNetworkService()) {
        self.companyFinancialsNetworkService = companyFinancialsNetworkService
    }
    
    func fetchCompanyFinancials(cik: Int) {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        companyFinancialsNetworkService.getCompanyFinancials(cik: cik)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] facts in
                self?.companyFacts = facts
                self?.calculateMetrics(facts: facts)
            })
            .store(in: &cancellables)
    }
    
    private func calculateMetrics(facts: CompanyFacts) {
        let calculator = BigFiveCalculator(facts: facts)
        bigFiveMetrics = calculator.calculateMetrics()
    }
}
