//
//  SUIMainView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI

struct SUIMainView: View {
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                SUICompanyListView(coordinator: coordinator)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { coordinator.authViewModel.signOut() }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
            }
            .tabItem { Label("Companies", systemImage: "building.2") }
            
            NavigationStack {
                SUIWatchListView(coordinator: coordinator)
            }
            .tabItem { Label("Watch List", systemImage: "eye.fill") }
            
            NavigationStack {
                SUIAIChatView(viewModel: coordinator.aichatViewModel)
            }
            .tabItem { Label("AI Analysis", systemImage: "brain") }
        }
    }
}
