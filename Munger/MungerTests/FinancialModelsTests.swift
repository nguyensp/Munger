//
//  FinancialModelsTests.swift
//  MungerTests
//
//  Created by Paul Nguyen on 2/20/25.
//

import XCTest
@testable import Munger

class FinancialModelsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // Load JSON from test bundle
    private func loadJSONFromBundle(filename: String) -> Data {
        guard let url = Bundle(for: type(of: self)).url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            XCTFail("Failed to load \(filename).json from test bundle")
            return Data()
        }
        print("[Test] Loaded \(filename).json, size: \(data.count) bytes")
        return data
    }
    
    func testFullJSONDecoding() {
        let jsonData = loadJSONFromBundle(filename: "apple_financials")
        let decoder = JSONDecoder()
        do {
            let facts = try decoder.decode(CompanyFacts.self, from: jsonData)
            XCTAssertEqual(facts.cik, 320193, "CIK should be 320193")
            XCTAssertEqual(facts.entityName, "Apple Inc.", "Entity name should be Apple Inc.")
            XCTAssertGreaterThanOrEqual(facts.facts.usGaap?.count ?? 0, 500, "Should decode ~500 us-gaap metrics")
            
            guard let revenues = facts.facts.usGaap?["Revenues"]?.units["USD"] else {
                XCTFail("Revenues data not found")
                return
            }
            XCTAssertGreaterThanOrEqual(revenues.count, 16, "Should decode 16+ Revenues data points")
            let annualRevenues = revenues.filter { $0.isAnnual }
            XCTAssertGreaterThanOrEqual(annualRevenues.count, 16, "Should filter 16+ annual Revenues points")
            print("[Test] Decoded Revenues points: \(revenues.count), Annual: \(annualRevenues.count)")
            
            guard let eps = facts.facts.usGaap?["EarningsPerShareDiluted"]?.units["pure"] else {
                XCTFail("EPS data not found")
                return
            }
            XCTAssertGreaterThanOrEqual(eps.count, 16, "Should decode 16+ EPS data points")
            let annualEPS = eps.filter { $0.isAnnual }
            XCTAssertGreaterThanOrEqual(annualEPS.count, 16, "Should filter 16+ annual EPS points")
            print("[Test] Decoded EPS points: \(eps.count), Annual: \(annualEPS.count)")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    // Subset of Apple JSON from Gist (Revenues and EPS for 2013, 2023)
    private func mockJSON() -> String {
        return """
        {
            "cik": 320193,
            "entityName": "Apple Inc.",
            "facts": {
                "us-gaap": {
                    "Revenues": {
                        "label": "Revenues",
                        "description": "Amount of revenue recognized from goods sold, services rendered, insurance premiums, or other activities that constitute an earning process.",
                        "units": {
                            "USD": [
                                {
                                    "start": "2012-09-30",
                                    "end": "2013-09-28",
                                    "val": 170910000000,
                                    "fy": 2013,
                                    "fp": "FY",
                                    "form": "10-K",
                                    "filed": "2013-10-30"
                                },
                                {
                                    "start": "2022-10-01",
                                    "end": "2023-09-30",
                                    "val": 383285000000,
                                    "fy": 2023,
                                    "fp": "FY",
                                    "form": "10-K",
                                    "filed": "2023-11-03"
                                }
                            ]
                        }
                    },
                    "EarningsPerShareDiluted": {
                        "label": "Earnings Per Share, Diluted",
                        "description": "The amount of net income (loss) for the period available to each share of common stock or common unit outstanding during the reporting period.",
                        "units": {
                            "pure": [
                                {
                                    "end": "2013-09-28",
                                    "val": 1.42,
                                    "fy": 2013,
                                    "fp": "FY",
                                    "form": "10-K",
                                    "filed": "2013-10-30"
                                },
                                {
                                    "end": "2023-09-30",
                                    "val": 6.13,
                                    "fy": 2023,
                                    "fp": "FY",
                                    "form": "10-K",
                                    "filed": "2023-11-03"
                                }
                            ]
                        }
                    }
                }
            }
        }
        """
    }
    
    func testCompanyFactsDecoding() {
        guard let jsonData = mockJSON().data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let facts = try decoder.decode(CompanyFacts.self, from: jsonData)
            XCTAssertEqual(facts.cik, 320193, "CIK should be 320193")
            XCTAssertEqual(facts.entityName, "Apple Inc.", "Entity name should be Apple Inc.")
            XCTAssertNotNil(facts.facts.usGaap, "us-gaap data should exist")
            XCTAssertEqual(facts.facts.usGaap?.count, 2, "Should decode 2 us-gaap metrics")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    func testRevenuesDecoding() {
        guard let jsonData = mockJSON().data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let facts = try decoder.decode(CompanyFacts.self, from: jsonData)
            guard let revenues = facts.facts.usGaap?["Revenues"]?.units["USD"] else {
                XCTFail("Revenues data not found")
                return
            }
            XCTAssertEqual(revenues.count, 2, "Should decode 2 Revenues data points")
            let revenue2013 = revenues.first { $0.fy == 2013 }
            XCTAssertEqual(revenue2013?.val, 170910000000, "2013 Revenues should be 170.91B")
            let revenue2023 = revenues.first { $0.fy == 2023 }
            XCTAssertEqual(revenue2023?.val, 383285000000, "2023 Revenues should be 383.285B")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    func testEPSDecoding() {
        guard let jsonData = mockJSON().data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let facts = try decoder.decode(CompanyFacts.self, from: jsonData)
            guard let eps = facts.facts.usGaap?["EarningsPerShareDiluted"]?.units["pure"] else {
                XCTFail("EPS data not found")
                return
            }
            XCTAssertEqual(eps.count, 2, "Should decode 2 EPS data points")
            let eps2013 = eps.first { $0.fy == 2013 }
            XCTAssertEqual(eps2013?.val, 1.42, "2013 EPS should be 1.42")
            let eps2023 = eps.first { $0.fy == 2023 }
            XCTAssertEqual(eps2023?.val, 6.13, "2023 EPS should be 6.13")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    func testAnnualFiltering() {
        guard let jsonData = mockJSON().data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let facts = try decoder.decode(CompanyFacts.self, from: jsonData)
            guard let revenues = facts.facts.usGaap?["Revenues"]?.units["USD"] else {
                XCTFail("Revenues data not found")
                return
            }
            let annualPoints = revenues.filter { $0.isAnnual }
            XCTAssertEqual(annualPoints.count, 2, "Should filter 2 annual Revenues points")
            XCTAssertTrue(annualPoints.allSatisfy { $0.form == "10-K" }, "All points should be 10-K")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
}
