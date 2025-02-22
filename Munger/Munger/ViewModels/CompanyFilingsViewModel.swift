//
//  CompanyFilingsViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 2/10/25.
//

import Foundation
import Combine

class CompanyFilingsViewModel: ObservableObject {
    @Published var filings: [Filing] = []
    @Published var isLoading: Bool = false
    @Published var selectedFiling: Filing?
    @Published var pdfData: Data?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let secFilingNetworkService: SECFilingNetworkService
    
    init(secFilingNetworkService: SECFilingNetworkService) {
        self.secFilingNetworkService = secFilingNetworkService
    }
    
    func fetchFilings(cik: Int) {
        if isLoading { return }
        
        isLoading = true
        error = nil
        
        secFilingNetworkService.getFilings(cik: cik)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            }, receiveValue: { [weak self] filings in
                self?.filings = filings
            })
            .store(in: &cancellables)
    }
    
    func fetchPDF(for filing: Filing) {
        isLoading = true
        error = nil
        selectedFiling = filing
        pdfData = nil
        
        secFilingNetworkService.getFilingPDF(url: filing.documentUrl)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            }, receiveValue: { [weak self] data in
                self?.pdfData = data
            })
            .store(in: &cancellables)
    }
}
