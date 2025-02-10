//
//  ContentView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var watchListManager = WatchListManager()
    
    var body: some View {
        TabView {
            NavigationStack {
                SUICompanyListView()
            }
            .tabItem {
                Label("Companies", systemImage: "building.2")
            }
            
            NavigationStack {
                SUIWatchListView(viewModel: WatchListViewModel(watchListManager: watchListManager))
            }
            .tabItem {
                Label("Watch List", systemImage: "star.fill")
            }
            
            NavigationStack {
                SUIChatView()
            }
            .tabItem {
                Label("AI Analysis", systemImage: "brain")
            }
        }
        .environmentObject(watchListManager)
    }
}

