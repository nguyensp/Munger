//
//  SECFilingNetworkService.swift
//  Munger
//
//  Created by Paul Nguyen on 2/10/25.
//

import Foundation
import Combine

struct Filing {
    let accessionNumber: String
    let form: String
    let fileNumber: String
    let filmNumber: String
    let items: String
    let size: Int
    let filingDate: Date
    let filingUrl: String
    let documentUrl: String
    let primaryDocument: String
    let description: String
}

public final class SECFilingNetworkService {
    private let requestDispatcher: RequestDispatcher
    
    init(requestDispatcher: RequestDispatcher) {
        self.requestDispatcher = requestDispatcher
    }
    
    func getFilings(cik: Int) -> AnyPublisher<[Filing], Error> {
        let paddedCik = String(format: "%010d", cik)
        let baseURL = "https://data.sec.gov/submissions/CIK\(paddedCik).json"
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = RequestBuilder.createGetRequest(from: url)
        urlRequest.setValue("Paul Nguyen paulsngyn@gmail.com", forHTTPHeaderField: "User-Agent")
        
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { data -> [Filing] in
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                do {
                    let response = try decoder.decode(SECSubmissionResponse.self, from: data)
                    let filings = response.filings.recent
                    
                    var result: [Filing] = []
                    
                    // Iterate through all indices
                    for i in 0..<filings.accessionNumber.count {
                        // Only process 10-K filings
                        if filings.form[i] == "10-K" {
                            let cleanAccessionNumber = filings.accessionNumber[i].replacingOccurrences(of: "-", with: "")
                            let primaryDocument = filings.primaryDocument?[i] ?? ""
                            let unpaddedCik = String(Int(paddedCik) ?? 0)
                            let baseUrl = "https://www.sec.gov/Archives/edgar/data/\(unpaddedCik)/\(cleanAccessionNumber)/"
                            
                            // Create the ix viewer URL
                            let documentUrl = "https://www.sec.gov/ix?doc=/Archives/edgar/data/\(unpaddedCik)/\(cleanAccessionNumber)/\(primaryDocument)"
                            
                            result.append(Filing(
                                accessionNumber: cleanAccessionNumber,
                                form: filings.form[i],
                                fileNumber: filings.fileNumber?[i] ?? "",
                                filmNumber: filings.filmNumber?[i] ?? "",
                                items: filings.items?[i] ?? "",
                                size: filings.size?[i] ?? 0,
                                filingDate: filings.filingDate[i],
                                filingUrl: baseUrl,
                                documentUrl: documentUrl,
                                primaryDocument: primaryDocument,
                                description: filings.description?[i] ?? ""
                            ))
                        }
                    }
                    
                    return result
                } catch {
                    print("Decoding error: \(error)")
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getFilingPDF(url: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var urlRequest = RequestBuilder.createGetRequest(from: url)
        urlRequest.setValue("Paul Nguyen paulsngyn@gmail.com", forHTTPHeaderField: "User-Agent")
        
        return requestDispatcher.dispatch(request: urlRequest)
            .eraseToAnyPublisher()
    }
}

// Response Models matching the actual SEC Submissions API format
private struct SECSubmissionResponse: Codable {
    let cik: String
    let entityType: String
    let sic: String
    let sicDescription: String
    let name: String
    let tickers: [String]
    let exchanges: [String]
    let filings: SECFilings
}

private struct SECFilings: Codable {
    let recent: FilingList
}

private struct FilingList: Codable {
    let accessionNumber: [String]
    let form: [String]
    let fileNumber: [String]?
    let filmNumber: [String]?
    let items: [String]?
    let size: [Int]?
    let filingDate: [Date]
    let primaryDocument: [String]?
    let description: [String]?
}
