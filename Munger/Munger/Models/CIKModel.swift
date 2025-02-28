//
//  CIKModel.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

/**
 {
   "fields": [
     "cik",
     "name",
     "ticker",
     "exchange"
   ],
   "data": [
     [320193, "Apple Inc.",
       "AAPL",
       "Nasdaq"
     ],
     [789019, "MICROSOFT CORP",
       "MSFT",
       "Nasdaq"
     ],
     [1045810, "NVIDIA CORP",
       "NVDA",
       "Nasdaq"
     ],
 */
struct CIKResponse: Codable {
    struct CompanyData: Codable {
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            cik = try container.decode(Int.self)
            name = try container.decode(String.self)
            ticker = try container.decode(String.self)
            exchange = try container.decodeIfPresent(String.self)  // Make optional
        }
        
        let cik: Int
        let name: String
        let ticker: String
        let exchange: String?  // Optional to handle null values
    }

    let fields: [String]
    let data: [CompanyData]
    
    var companies: [Company] {
        data.map { companyData in
            Company(
                cik: companyData.cik,
                companyName: companyData.name,
                companyTicker: companyData.ticker,
                companyExchange: companyData.exchange ?? "Unknown"  // Provide default value
            )
        }
    }
}

struct Company: Identifiable {
    let cik: Int
    let companyName: String
    let companyTicker: String
    let companyExchange: String
    var id: String { companyTicker }
}
