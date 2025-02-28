//
//  SUIMainView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI

struct SUIMainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                SUICompanyListView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { authViewModel.signOut() }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
            }
            .tabItem { Label("Companies", systemImage: "building.2") }
            
            NavigationStack {
                SUIWatchListView()
            }
            .tabItem { Label("Watch List", systemImage: "eye.fill") }
            
            NavigationStack {
                SUIAIChatView()
            }
            .tabItem { Label("AI Analysis", systemImage: "brain") }
        }
    }
}
