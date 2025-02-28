//
//  UserMetricsManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/27/25.
//

import Foundation

struct UserMetricYear: MetricYearProtocol {
    let metricKey: String
    let year: Int
}

/// Allow user to save metrics pertinent to them
class UserMetricsManager: BaseMetricManager<UserMetricYear> {
    init() {
        super.init(storageKey: "WatchedUserMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> UserMetricYear {
        return UserMetricYear(metricKey: metricKey, year: year)
    }
    
    // New method to clear saved user metrics for a specific company
    func clearMetrics(companyCik: Int) {
        var updatedWatched = watchedMetricYears
        let cikKey = String(companyCik)
        updatedWatched.removeValue(forKey: cikKey)
        updateWatchedMetricYears(updatedWatched)
        saveWatchedMetricYears()
        print("Cleared user metrics for CIK \(companyCik)")
    }
    
    // Optional: Method to clear all user metrics
    func clearAllMetrics() {
        updateWatchedMetricYears([:])
        saveWatchedMetricYears()
        print("Cleared all user metrics")
    }
}
