//
//  DataMigration.swift
//  Munger
//
//  Created by Paul Nguyen on 2/27/25.
//

import Foundation

struct DataMigration {
    static let migrationCompletedKey = "MigratedFromOldWatchlistManager"
    
    static func migrateIfNeeded(
        userDefaults: UserDefaults = .standard,
        userMetricsManager: UserMetricsManager,
        roicManager: ROICManager
    ) {
        // Check if migration has already been performed
        if userDefaults.bool(forKey: migrationCompletedKey) {
            return
        }
        
        // Get old data
        let oldStorageKey = "WatchedMetricYears"
        guard let oldData = userDefaults.data(forKey: oldStorageKey) else {
            // No old data, mark as migrated and return
            userDefaults.set(true, forKey: migrationCompletedKey)
            return
        }
        
        // Define a standalone MetricYear struct for decoding old data
        struct OldMetricYear: Hashable, Codable {
            let metricKey: String
            let year: Int
        }
        
        // Try to decode the old data
        guard let oldWatchedMetricYears = try? JSONDecoder().decode([String: Set<OldMetricYear>].self, from: oldData) else {
            // Couldn't decode, mark as migrated and return
            userDefaults.set(true, forKey: migrationCompletedKey)
            return
        }
        
        // Set of ROIC-specific metric keys
        let roicMetricKeys = Set(["NetIncomeLoss", "Assets", "LiabilitiesCurrent"])
        
        // Process each company's metrics
        for (cikKey, metricYears) in oldWatchedMetricYears {
            guard let companyCik = Int(cikKey) else { continue }
            
            for metricYear in metricYears {
                if roicMetricKeys.contains(metricYear.metricKey) {
                    // Add to ROIC manager
                    roicManager.toggleMetricYear(
                        companyCik: companyCik,
                        metricKey: metricYear.metricKey,
                        year: metricYear.year
                    )
                } else {
                    // Add to user metrics manager
                    userMetricsManager.toggleMetricYear(
                        companyCik: companyCik,
                        metricKey: metricYear.metricKey,
                        year: metricYear.year
                    )
                }
            }
        }
        
        // Mark migration as completed
        userDefaults.set(true, forKey: migrationCompletedKey)
        
        // Optionally, clean up old data
        userDefaults.removeObject(forKey: oldStorageKey)
    }
}
