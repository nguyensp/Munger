//
//  BigFiveCalculatorTests.swift
//  MungerTests
//
//  Created by Paul Nguyen on 2/20/25.
//

import XCTest
@testable import Munger

class BigFiveCalculatorTests: XCTestCase {
    
    var calculator: BigFiveCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = BigFiveCalculator(facts: mockCompanyFacts())
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // Mock Apple data for 2013–2023 (expanded from Gist)
    private func mockCompanyFacts() -> CompanyFacts {
        let facts = Facts(
            usGaap: [
                "OperatingIncomeLoss": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 48999000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 114301000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "Assets": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 207000000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 352755000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "CashAndCashEquivalentsAtCarryingValue": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 14259000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 29965000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "Liabilities": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 83451000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 290437000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "MarketableSecuritiesNoncurrent": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 106215000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 100544000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "LongTermDebtNoncurrent": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 16960000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 95281000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "Revenues": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: "2012-09-30", end: "2013-09-28", val: 170910000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: "2022-10-01", end: "2023-09-30", val: 383285000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "EarningsPerShareDiluted": MetricData(
                    label: nil, description: nil,
                    units: ["pure": [
                        DataPoint(start: nil, end: "2013-09-28", val: 1.42, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 6.13, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "StockholdersEquity": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: nil, end: "2013-09-28", val: 123549000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: nil, end: "2023-09-30", val: 62146000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "NetCashProvidedByUsedInOperatingActivities": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: "2012-09-30", end: "2013-09-28", val: 53666000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: "2022-10-01", end: "2023-09-30", val: 110543000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "PaymentsToAcquirePropertyPlantAndEquipment": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: "2012-09-30", end: "2013-09-28", val: 8165000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: "2022-10-01", end: "2023-09-30", val: 10959000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: "2012-09-30", end: "2013-09-28", val: 50155000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: "2022-10-01", end: "2023-09-30", val: 113736000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                ),
                "IncomeTaxExpenseBenefit": MetricData(
                    label: nil, description: nil,
                    units: ["USD": [
                        DataPoint(start: "2012-09-30", end: "2013-09-28", val: 13118000000, fy: 2013, fp: "FY", form: "10-K", filed: "2013-10-30", accn: nil, frame: nil),
                        DataPoint(start: "2022-10-01", end: "2023-09-30", val: 16741000000, fy: 2023, fp: "FY", form: "10-K", filed: "2023-11-03", accn: nil, frame: nil)
                    ]]
                )
            ],
            dei: nil
        )
        return CompanyFacts(cik: 320193, entityName: "Apple Inc.", facts: facts)
    }
    
    func testROICCalculation() {
        let metrics = calculator.calculateMetrics()
        let metric2023 = metrics.first { $0.year == 2023 }
        
        XCTAssertNotNil(metric2023, "Metric for 2023 should exist")
        let expectedROIC = 42.6 // Manual calc: ($97.16B NOPAT / $228.18B IC) * 100
        XCTAssertEqual(metric2023!.roic, expectedROIC, accuracy: 1.0, "ROIC for 2023 should be approximately 42.6%")
    }
    
    func testSalesGrowthCalculation() {
        let metrics = calculator.calculateMetrics()
        let metric2023 = metrics.first { $0.year == 2023 }
        
        XCTAssertNotNil(metric2023?.salesGrowth, "Sales growth for 2023 should exist")
        let expected10YearSalesGrowth = 8.4 // ($383.29B / $170.91B)^(1/10) - 1 * 100
        XCTAssertEqual(metric2023!.salesGrowth!.tenYear!, expected10YearSalesGrowth, accuracy: 0.5, "10-year sales growth for 2023 should be approximately 8.4%")
    }
    
    func testEPSGrowthCalculation() {
        let metrics = calculator.calculateMetrics()
        let metric2023 = metrics.first { $0.year == 2023 }
        
        XCTAssertNotNil(metric2023?.epsGrowth, "EPS growth for 2023 should exist")
        let expected10YearEPSGrowth = 15.7 // ($6.13 / $1.42)^(1/10) - 1 * 100
        XCTAssertEqual(metric2023!.epsGrowth!.tenYear!, expected10YearEPSGrowth, accuracy: 1.0, "10-year EPS growth for 2023 should be approximately 15.7%")
    }
    
    func testEquityGrowthCalculation() {
        let metrics = calculator.calculateMetrics()
        let metric2023 = metrics.first { $0.year == 2023 }
        
        XCTAssertNotNil(metric2023?.equityGrowth, "Equity growth for 2023 should exist")
        let expected10YearEquityGrowth = -6.6 // ($62.15B / $123.55B)^(1/10) - 1 * 100
        XCTAssertEqual(metric2023!.equityGrowth!.tenYear!, expected10YearEquityGrowth, accuracy: 0.5, "10-year equity growth for 2023 should be approximately -6.6%")
    }
    
    func testFCFGrowthCalculation() {
        let metrics = calculator.calculateMetrics()
        let metric2023 = metrics.first { $0.year == 2023 }
        
        XCTAssertNotNil(metric2023?.fcfGrowth, "FCF growth for 2023 should exist")
        let expected10YearFCFGrowth = 8.15 // Updated: ($99.58B / $45.50B)^(1/10) - 1 * 100
        XCTAssertEqual(metric2023!.fcfGrowth!.tenYear!, expected10YearFCFGrowth, accuracy: 0.5, "10-year FCF growth for 2023 should be approximately 8.15%")
    }
}
