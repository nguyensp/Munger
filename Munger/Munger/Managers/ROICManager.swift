//
//  ROICManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/27/25.
//

import Foundation

struct ROICMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

class ROICManager: BaseMetricManager<ROICMetricYear> {
    private let requiredKeys = ["NetIncomeLoss", "Assets", "LiabilitiesCurrent"]
    
    init() {
        super.init(storageKey: "WatchedROICMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> ROICMetricYear {
        return ROICMetricYear(metricKey: metricKey, year: year)
    }
    
    func gatherROICMetrics(companyCik: Int, facts: CompanyFacts) {
        gatherMetrics(companyCik: companyCik, facts: facts, requiredKeys: requiredKeys)
    }
    
    override func gatherMetrics(companyCik: Int, facts: CompanyFacts, requiredKeys: [String]) {
        let cikKey = String(companyCik)
        var updatedWatched = watchedMetricYears
        var metricYears = updatedWatched[cikKey] ?? Set<ROICMetricYear>()
        
        guard let usGaap = facts.facts.usGaap else { return }
        
        for key in requiredKeys {
            guard requiredKeys.contains(key) else {
                print("Warning: Attempted to gather non-ROIC metric \(key) in ROICManager")
                continue
            }
            if let metricData = usGaap[key],
               let dataPoints = metricData.units["USD"]?.filter({ $0.isAnnual }) {
                for dataPoint in dataPoints {
                    metricYears.insert(createMetricYear(metricKey: key, year: dataPoint.fy))
                }
            }
        }
        
        if metricYears.isEmpty {
            updatedWatched.removeValue(forKey: cikKey)
        } else {
            updatedWatched[cikKey] = metricYears
        }
        
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
    }
    
    override func loadWatchedMetricYears() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: Set<ROICMetricYear>].self, from: data) {
            var cleanedData = decoded
            for (cik, metrics) in decoded {
                let filteredMetrics = metrics.filter { requiredKeys.contains($0.metricKey) }
                if filteredMetrics.isEmpty {
                    cleanedData.removeValue(forKey: cik)
                } else {
                    cleanedData[cik] = filteredMetrics
                }
            }
            print("Loaded ROIC metrics from \(storageKey):")
            for (cik, metrics) in cleanedData {
                print("CIK \(cik): \(metrics.map { "\($0.metricKey) (\($0.year))" })")
            }
            updateWatchedMetricYears(cleanedData)
            saveWatchedMetricYears() // Persist the cleaned data
        }
    }
    
    func roicReadyYears(companyCik: Int, facts: CompanyFacts) -> [Int] {
        return readyYears(companyCik: companyCik, facts: facts, requiredKeys: Set(requiredKeys))
    }
    
    func calculateROICForYear(companyCik: Int, year: Int, facts: CompanyFacts) -> Double? {
        guard let netIncome = getMetricValue(companyCik: companyCik, year: year, key: "NetIncomeLoss", facts: facts),
              let assets = getMetricValue(companyCik: companyCik, year: year, key: "Assets", facts: facts),
              let currentLiabilities = getMetricValue(companyCik: companyCik, year: year, key: "LiabilitiesCurrent", facts: facts),
              assets - currentLiabilities != 0 else { return nil }
        
        let investedCapital = assets - currentLiabilities
        return netIncome / investedCapital
    }
    
    func calculateROICAverages(companyCik: Int, facts: CompanyFacts, periods: [Int]) -> [Int: Double] {
        let availableYears = roicReadyYears(companyCik: companyCik, facts: facts)
        let yearsCount = availableYears.count
        var averages: [Int: Double] = [:]
        
        for period in periods.filter({ $0 <= yearsCount }) {
            let recentYears = Array(availableYears.prefix(period))
            if !recentYears.isEmpty {
                let roicValues = recentYears.compactMap { year in
                    calculateROICForYear(companyCik: companyCik, year: year, facts: facts)
                }
                if !roicValues.isEmpty {
                    let avg = roicValues.reduce(0.0, +) / Double(roicValues.count)
                    averages[period] = avg * 100 // Store as percentage
                }
            }
        }
        
        return averages
    }
    
    func clearMetrics(companyCik: Int) {
        var updatedWatched = watchedMetricYears
        let cikKey = String(companyCik)
        updatedWatched.removeValue(forKey: cikKey)
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
        print("Cleared ROIC metrics for CIK \(companyCik)")
    }
    
    func clearAllMetrics() {
        updateWatchedMetricYears([:])
        saveWatchedMetricYears()
        print("Cleared all ROIC metrics")
    }
}
