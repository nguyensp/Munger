//
//  CentralIndexKeyNetworkService.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation
import Combine

/// `CentralIndexKeyNetworkService` retrieves all companies that have a CIK keys available
public final class CentralIndexKeyNetworkService {
    private let requestDispatcher: RequestDispatcher
    
    private let baseURL: String = "https://www.sec.gov/files/company_tickers_exchange.json"
    
    init(requestDispatcher: RequestDispatcher) {
        self.requestDispatcher = requestDispatcher
    }
    
    /// Creates a URLRequest using `RequestBuilder` and dispatches the request with a `RequestDispatcher`.
    /// Response is modeled with `CIKModel`
    func getCompanyTickers() -> AnyPublisher<[Company], Error> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        var urlRequest = RequestBuilder.createGetRequest(from: url)
        urlRequest.setValue("Paul Nguyen paulsngyn@gmail.com", forHTTPHeaderField: "User-Agent")
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { data -> CIKResponse in
                return try JSONDecoder().decode(CIKResponse.self, from: data)
            }
            .map {
                $0.companies
            }
            .eraseToAnyPublisher()
    }
}
