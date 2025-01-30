//
//  MungerNetworkService.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation
import Combine

class MungerNetworkService {
    private let requestDispatcher: RequestDispatcher
    
    private let baseURL: String = "https://www.sec.gov/files/company_tickers_exchange.json"
    
    init(requestDispatcher: RequestDispatcher = URLSessionCombineDispatcher()) {
        self.requestDispatcher = requestDispatcher
    }
    
    func getCompanyTickers() -> AnyPublisher<[Company], Error> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        var urlRequest = RequestBuilder.createGetRequest(from: url)
        urlRequest.setValue("Paul Nguyen paulsngyn@gmail.com", forHTTPHeaderField: "User-Agent")
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { data -> TickerResponse in
                return try JSONDecoder().decode(TickerResponse.self, from: data)
            }
            .map {
                $0.companies
            }
            .eraseToAnyPublisher()
    }
}
