//
//  FinancialModels.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import Foundation

// Sample JSON structure:
/*
{
  "cik": 320193,
  "entityName": "Apple Inc.",
  "facts": {
    "us-gaap": {
      "NetIncomeLoss": {
        "label": "Net Income (Loss)",
        "description": "...",
        "units": {
          "USD": [
            {
              "end": "2023-09-30",
              "val": 96995000000,
              "accn": "0000320193-23-000077",
              "fy": 2023,
              "fp": "FY",
              "form": "10-K",
              "filed": "2023-10-27"
            },
            // More periods...
          ]
        }
      },
      "Assets": {
        // Similar structure...
      }
    }
  }
}
*/

struct CompanyFacts: Codable {
    let cik: Int
    let entityName: String
    let facts: Facts
}

struct Facts: Codable {
    let usGaap: [String: MetricData]
    
    enum CodingKeys: String, CodingKey {
        case usGaap = "us-gaap"
    }
}

struct MetricData: Codable {
    let units: [String: [DataPoint]]
}

struct DataPoint: Codable {
    let end: String
    let val: Double
    let fy: Int      // Fiscal Year
    let fp: String   // Fiscal Period
    let form: String // 10-K, 10-Q, etc.
    let filed: String
}

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
