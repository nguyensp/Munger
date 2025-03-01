//
//  SUIRootView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/19/25.
//

import SwiftUI

struct SUIRootView: View {
    private let coordinator: AppCoordinator
    @State private var isAuthenticated: Bool
    
    init(serviceFactory: ServiceFactoryProtocol) {
        self.coordinator = AppCoordinator(serviceFactory: serviceFactory)
        self._isAuthenticated = State(initialValue: coordinator.authViewModel.isAuthenticated)
    }
    
    var body: some View {
        NavigationStack {
            if isAuthenticated {
                SUIMainView()
            } else {
                SUIAuthenticationView()
            }
        }
        .environmentObject(coordinator.authViewModel)
        .environmentObject(coordinator.companyListViewModel)
        .environmentObject(coordinator.watchListViewModel)
        .environmentObject(coordinator.aichatViewModel)
        .environmentObject(coordinator.companyFilingsViewModel)
        .environmentObject(coordinator.companyFinancialsViewModel)
        .environmentObject(coordinator.watchListManager)
        .environmentObject(coordinator.userMetricsManager)
        .environmentObject(coordinator.watchListManager)
        .environmentObject(coordinator.roicManager)
        .environmentObject(coordinator.epsGrowthManager)
        .environmentObject(coordinator.salesGrowthManager)
        .environmentObject(coordinator.bookValueGrowthManager)
        .environmentObject(coordinator.fcfGrowthManager)
        .onReceive(coordinator.authViewModel.$isAuthenticated) { newValue in
            isAuthenticated = newValue
        }
    }
}

#Preview {
    let factory = ServiceFactory()
    SUIRootView(serviceFactory: factory)
}
