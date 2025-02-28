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
                SUIMainView(coordinator: coordinator)
                    .environmentObject(coordinator.authViewModel)
                    .environmentObject(coordinator.watchListManager)
                    .environmentObject(coordinator.userMetricsManager)
                    .environmentObject(coordinator.roicManager)
            } else {
                SUIAuthenticationView()
                    .environmentObject(coordinator.authViewModel)
            }
        }
        .onReceive(coordinator.authViewModel.$isAuthenticated) { newValue in
            isAuthenticated = newValue
        }
    }
}

#Preview {
    let factory = ServiceFactory()
    SUIRootView(serviceFactory: factory)
}
