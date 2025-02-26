//
//  MetricsWatchListManager.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import Foundation

class MetricsWatchListManager: ObservableObject {
    @Published private(set) var watchedMetrics: [String: Set<String>] = [:] // [CIK: Set<MetricKey>]
    
    func toggleMetric(companyCik: Int, metricKey: String) {
        let cikKey = String(companyCik)
        var metrics = watchedMetrics[cikKey] ?? Set<String>()
        if metrics.contains(metricKey) {
            metrics.remove(metricKey)
        } else {
            metrics.insert(metricKey)
        }
        watchedMetrics[cikKey] = metrics.isEmpty ? nil : metrics
    }
    
    func isWatched(companyCik: Int, metricKey: String) -> Bool {
        watchedMetrics[String(companyCik)]?.contains(metricKey) ?? false
    }
}
