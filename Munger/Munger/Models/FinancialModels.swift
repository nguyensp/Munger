//
//  FinancialModels.swift
//  Munger
//
//  Created by Paul Nguyen on 1/31/25.
//

import Foundation

/// Represents the full company financial facts from SEC EDGAR API.
struct CompanyFacts: Codable {
    let cik: Int
    let entityName: String
    let facts: Facts
}

/// Holds financial and metadata facts, split by taxonomy.
struct Facts: Codable {
    let usGaap: [String: MetricData]?
    let dei: [String: MetricData]?

    enum CodingKeys: String, CodingKey {
        case usGaap = "us-gaap"
        case dei
    }
}

/// Describes a financial metric (e.g., Revenues, Assets) with its data points.
struct MetricData: Codable {
    let label: String?
    let description: String?
    let units: [String: [DataPoint]]
}

/// A single data point for a metric (e.g., revenue for FY2023).
struct DataPoint: Codable {
    let start: String?   // Optional: Start date for duration metrics (e.g., revenue)
    let end: String      // End date of the period or snapshot
    let val: Double      // Value (e.g., dollars, shares)
    let fy: Int          // Fiscal year
    let fp: String       // Fiscal period (e.g., "FY", "Q1")
    let form: String     // Filing type (e.g., "10-K", "10-Q")
    let filed: String    // Filing date
    let accn: String?    // Accession number (optional, for reference)
    let frame: String?   // Calendar frame (optional)

    /// Determines if this is an annual filing (10-K).
    var isAnnual: Bool {
        form == "10-K"
    }
}

/// Utility extension for averaging arrays of Doubles.
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
