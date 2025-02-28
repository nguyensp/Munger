//
//  MetricsDashboardView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI
import Charts

struct MetricsDashboardView: View {
    let facts: CompanyFacts
    @EnvironmentObject var roicManager: ROICManager
    @EnvironmentObject var epsGrowthManager: EPSGrowthManager
    @EnvironmentObject var salesGrowthManager: SalesGrowthManager
    @EnvironmentObject var equityGrowthManager: EquityGrowthManager
    @EnvironmentObject var freeCashFlowManager: FreeCashFlowManager
    
    @State private var selectedPeriod = 5 // Default to 5-year metrics
    private let periods = [10, 7, 5, 3, 1]
    
    @State private var roicData: [Int: Double] = [:]
    @State private var epsGrowthData: [Int: Double] = [:]
    @State private var salesGrowthData: [Int: Double] = [:]
    @State private var equityGrowthData: [Int: Double] = [:]
    @State private var fcfGrowthData: [Int: Double] = [:]
    
    @State private var hasGatheredData = false
    @State private var showingDetailView = false
    @State private var selectedMetric: MetricType?
    
    enum MetricType: String, CaseIterable {
        case roic = "ROIC"
        case epsGrowth = "EPS Growth"
        case salesGrowth = "Sales Growth"
        case equityGrowth = "Equity Growth"
        case fcfGrowth = "FCF Growth"
    }
    
    // Computed property to create the composite metrics service
    private var compositeMetricsService: CompositeMetricsService {
        CompositeMetricsService(
            roicManager: roicManager,
            epsGrowthManager: epsGrowthManager,
            salesGrowthManager: salesGrowthManager,
            equityGrowthManager: equityGrowthManager,
            freeCashFlowManager: freeCashFlowManager
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header and description
                VStack(alignment: .leading, spacing: 10) {
                    Text("Financial Dashboard")
                        .font(.title)
                        .bold()
                    
                    Text("\(facts.entityName) - CIK: \(facts.cik)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Period selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Time Period")
                        .font(.headline)
                    
                    PeriodSelectionView(selectedPeriod: $selectedPeriod, periods: periods)
                }
                
                // Metrics Graph
                VStack(alignment: .leading, spacing: 15) {
                    Text("Key Metrics at a Glance")
                        .font(.headline)
                    
                    if hasGatheredData {
                        MetricsChartView(
                            roicData: roicData[selectedPeriod] ?? 0,
                            epsGrowthData: epsGrowthData[selectedPeriod] ?? 0,
                            salesGrowthData: salesGrowthData[selectedPeriod] ?? 0,
                            equityGrowthData: equityGrowthData[selectedPeriod] ?? 0,
                            fcfGrowthData: fcfGrowthData[selectedPeriod] ?? 0,
                            onMetricTap: { metricType in
                                selectedMetric = metricType
                                showingDetailView = true
                            }
                        )
                    } else {
                        Text("Gather data to view metrics visualization")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Composite metrics section
                if hasGatheredData {
                    CompositeMetricsView(facts: facts, compositeMetricsService: compositeMetricsService)
                }
                
                // Gather Data Button
                Button(action: {
                    gatherAllMetrics()
                }) {
                    Text(hasGatheredData ? "Refresh Data" : "Gather All Metrics")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .sheet(isPresented: $showingDetailView) {
            if let metricType = selectedMetric {
                MetricDetailView(
                    facts: facts,
                    metricType: metricType,
                    roicManager: roicManager,
                    epsGrowthManager: epsGrowthManager,
                    salesGrowthManager: salesGrowthManager,
                    equityGrowthManager: equityGrowthManager,
                    freeCashFlowManager: freeCashFlowManager
                )
            }
        }
    }
    
    private func gatherAllMetrics() {
        // Gather data for all managers
        roicManager.gatherROICMetrics(companyCik: facts.cik, facts: facts)
        epsGrowthManager.gatherEPSGrowthMetrics(companyCik: facts.cik, facts: facts)
        salesGrowthManager.gatherSalesGrowthMetrics(companyCik: facts.cik, facts: facts)
        equityGrowthManager.gatherEquityGrowthMetrics(companyCik: facts.cik, facts: facts)
        freeCashFlowManager.gatherFreeCashFlowMetrics(companyCik: facts.cik, facts: facts)
        
        // Calculate metrics for each period
        for period in periods {
            // ROIC
            if let roicAvg = roicManager.calculateROICAverages(companyCik: facts.cik, facts: facts, periods: [period])[period] {
                roicData[period] = roicAvg
            }
            
            // EPS Growth
            if let epsGrowth = epsGrowthManager.calculateEPSGrowth(companyCik: facts.cik, period: period, facts: facts) {
                epsGrowthData[period] = epsGrowth * 100 // Convert to percentage
            }
            
            // Sales Growth
            if let salesGrowth = salesGrowthManager.calculateSalesGrowth(companyCik: facts.cik, period: period, facts: facts) {
                salesGrowthData[period] = salesGrowth * 100 // Convert to percentage
            }
            
            // Equity Growth
            if let equityGrowth = equityGrowthManager.calculateEquityGrowth(companyCik: facts.cik, period: period, facts: facts) {
                equityGrowthData[period] = equityGrowth * 100 // Convert to percentage
            }
            
            // FCF Growth
            if let fcfGrowth = freeCashFlowManager.calculateFreeCashFlowGrowth(companyCik: facts.cik, period: period, facts: facts) {
                fcfGrowthData[period] = fcfGrowth * 100 // Convert to percentage
            }
        }
        
        hasGatheredData = true
    }
}

struct PeriodSelectionView: View {
    @Binding var selectedPeriod: Int
    let periods: [Int]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(periods, id: \.self) { period in
                    Button(action: {
                        selectedPeriod = period
                    }) {
                        Text("\(period) Year\(period == 1 ? "" : "s")")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

struct MetricsChartView: View {
    let roicData: Double
    let epsGrowthData: Double
    let salesGrowthData: Double
    let equityGrowthData: Double
    let fcfGrowthData: Double
    let onMetricTap: (MetricsDashboardView.MetricType) -> Void
    
    var body: some View {
        VStack {
            Chart {
                BarMark(
                    x: .value("Category", "ROIC"),
                    y: .value("Value", roicData)
                )
                .foregroundStyle(Color.blue)
                .annotation(position: .top) {
                    Text("\(String(format: "%.1f%%", roicData))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                BarMark(
                    x: .value("Category", "EPS Growth"),
                    y: .value("Value", epsGrowthData)
                )
                .foregroundStyle(Color.green)
                .annotation(position: .top) {
                    Text("\(String(format: "%.1f%%", epsGrowthData))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                BarMark(
                    x: .value("Category", "Sales Growth"),
                    y: .value("Value", salesGrowthData)
                )
                .foregroundStyle(Color.orange)
                .annotation(position: .top) {
                    Text("\(String(format: "%.1f%%", salesGrowthData))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                BarMark(
                    x: .value("Category", "Equity Growth"),
                    y: .value("Value", equityGrowthData)
                )
                .foregroundStyle(Color.purple)
                .annotation(position: .top) {
                    Text("\(String(format: "%.1f%%", equityGrowthData))")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                BarMark(
                    x: .value("Category", "FCF Growth"),
                    y: .value("Value", fcfGrowthData)
                )
                .foregroundStyle(Color.red)
                .annotation(position: .top) {
                    Text("\(String(format: "%.1f%%", fcfGrowthData))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 0...(max(roicData, epsGrowthData, salesGrowthData, equityGrowthData, fcfGrowthData) * 1.2))
            
            // Interactive metric selection
            HStack {
                ForEach(MetricsDashboardView.MetricType.allCases, id: \.self) { metricType in
                    Button(action: {
                        onMetricTap(metricType)
                    }) {
                        Text(metricType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricDetailView: View {
    let facts: CompanyFacts
    let metricType: MetricsDashboardView.MetricType
    let roicManager: ROICManager
    let epsGrowthManager: EPSGrowthManager
    let salesGrowthManager: SalesGrowthManager
    let equityGrowthManager: EquityGrowthManager
    let freeCashFlowManager: FreeCashFlowManager
    
    @State private var yearlyData: [(year: Int, value: Double)] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // Historical chart
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Historical Performance")
                                .font(.headline)
                            
                            if yearlyData.isEmpty {
                                Text("No data available for this metric")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                Chart {
                                    ForEach(yearlyData, id: \.year) { item in
                                        LineMark(
                                            x: .value("Year", String(item.year)),
                                            y: .value("Value", item.value)
                                        )
                                        .symbol(.circle)
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 250)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Data table
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Raw Data")
                                .font(.headline)
                            
                            if yearlyData.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                VStack(spacing: 0) {
                                    // Header row
                                    HStack {
                                        Text("Year")
                                            .fontWeight(.bold)
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text("Value")
                                            .fontWeight(.bold)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemGray5))
                                    
                                    // Data rows
                                    ForEach(yearlyData.sorted(by: { $0.year > $1.year }), id: \.year) { item in
                                        HStack {
                                            Text("\(item.year)")
                                                .frame(width: 80, alignment: .leading)
                                            Spacer()
                                            Text(formatValue(item.value))
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemGray6))
                                    }
                                }
                                .cornerRadius(8)
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this Metric")
                                .font(.headline)
                            
                            Text(metricDescription)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .navigationTitle(metricType.rawValue)
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        switch metricType {
        case .roic:
            let years = roicManager.roicReadyYears(companyCik: facts.cik, facts: facts)
            yearlyData = years.compactMap { year in
                if let value = roicManager.calculateROICForYear(companyCik: facts.cik, year: year, facts: facts) {
                    return (year: year, value: value * 100) // Convert to percentage
                }
                return nil
            }
            
        case .epsGrowth:
            let years = epsGrowthManager.epsGrowthReadyYears(companyCik: facts.cik, facts: facts)
            yearlyData = years.compactMap { year in
                if let value = epsGrowthManager.calculateEPSForYear(companyCik: facts.cik, year: year, facts: facts) {
                    return (year: year, value: value)
                }
                return nil
            }
            
        case .salesGrowth:
            let years = salesGrowthManager.salesGrowthReadyYears(companyCik: facts.cik, facts: facts)
            yearlyData = years.compactMap { year in
                if let value = salesGrowthManager.getMetricValue(companyCik: facts.cik, year: year, key: "Revenues", facts: facts) {
                    return (year: year, value: value)
                }
                return nil
            }
            
        case .equityGrowth:
            let years = equityGrowthManager.equityGrowthReadyYears(companyCik: facts.cik, facts: facts)
            yearlyData = years.compactMap { year in
                if let value = equityGrowthManager.getMetricValue(companyCik: facts.cik, year: year, key: "StockholdersEquity", facts: facts) {
                    return (year: year, value: value)
                }
                return nil
            }
            
        case .fcfGrowth:
            let years = freeCashFlowManager.freeCashFlowReadyYears(companyCik: facts.cik, facts: facts)
            yearlyData = years.compactMap { year in
                if let value = freeCashFlowManager.calculateFreeCashFlowForYear(companyCik: facts.cik, year: year, facts: facts) {
                    return (year: year, value: value)
                }
                return nil
            }
        }
        
        isLoading = false
    }
    
    private var metricDescription: String {
        switch metricType {
        case .roic:
            return "Return on Invested Capital (ROIC) measures how efficiently a company uses its capital to generate returns. It's calculated as Net Income divided by Invested Capital (Total Assets - Current Liabilities). Higher ROIC indicates better capital allocation and is a strong indicator of value creation."
            
        case .epsGrowth:
            return "Earnings Per Share (EPS) Growth measures the growth in a company's net income on a per-share basis. It reflects the company's profitability growth taking into account changes in outstanding shares. Consistent EPS growth often correlates with stock price appreciation over time."
            
        case .salesGrowth:
            return "Sales Growth measures the percentage increase in a company's revenue over time. It's a fundamental indicator of a company's ability to expand its market and grow its business. Consistent sales growth is important for long-term business viability."
            
        case .equityGrowth:
            return "Equity Growth tracks the increase in a company's book value (total assets minus total liabilities). Growing equity indicates that a company is becoming more valuable from an accounting perspective, either by generating profits, raising capital, or both."
            
        case .fcfGrowth:
            return "Free Cash Flow (FCF) Growth measures the increase in a company's operating cash flow minus capital expenditures. FCF represents the cash a company generates after accounting for cash outflows to support operations and maintain capital assets. FCF growth is often seen as a purer measure of financial health than earnings growth."
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .roic:
            return String(format: "%.2f%%", value)
        case .epsGrowth:
            return String(format: "$%.2f", value)
        case .salesGrowth, .equityGrowth, .fcfGrowth:
            if abs(value) >= 1_000_000_000 {
                return String(format: "$%.2fB", value / 1_000_000_000)
            } else if abs(value) >= 1_000_000 {
                return String(format: "$%.2fM", value / 1_000_000)
            } else if abs(value) >= 1_000 {
                return String(format: "$%.2fK", value / 1_000)
            } else {
                return String(format: "$%.2f", value)
            }
        }
    }
}
