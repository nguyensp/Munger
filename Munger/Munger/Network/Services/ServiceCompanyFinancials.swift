//
//  ServiceCompanyFinancials.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import Foundation
import Combine

/// `ServiceCompanyFinancials` fetches company facts with specified CIK key
public final class ServiceCompanyFinancials {
   private let requestDispatcher: RequestDispatcher
    
    init(requestDispatcher: RequestDispatcher) {
        self.requestDispatcher = requestDispatcher
    }
    
    func getCompanyFinancials(cik: Int) -> AnyPublisher<CompanyFacts, Error> {
        let paddedCik = String(format: "%010d", cik) // Pad CIK to 10 digits
        let baseURL = "https://data.sec.gov/api/xbrl/companyfacts/CIK\(paddedCik).json"
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = RequestBuilder.createGetRequest(from: url)
        urlRequest.setValue("Paul Nguyen paulsngyn@gmail.com", forHTTPHeaderField: "User-Agent")
        
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { data -> CompanyFacts in
                return try JSONDecoder().decode(CompanyFacts.self, from: data)
            }
            .eraseToAnyPublisher()
    }
}
