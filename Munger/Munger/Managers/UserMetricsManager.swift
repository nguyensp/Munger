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

class UserMetricsManager: BaseMetricManager<UserMetricYear> {
    init() {
        super.init(storageKey: "WatchedUserMetricYears")
    }
    
    override func createMetricYear(metricKey: String, year: Int) -> UserMetricYear {
        return UserMetricYear(metricKey: metricKey, year: year)
    }
}
