//
//  ContentView.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import SwiftUI
import Combine

struct ContentView: View {
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
            .tabItem { Label("Watch List", systemImage: "star.fill") }
            
            NavigationStack {
                SUIChatView(viewModel: coordinator.chatViewModel)
            }
            .tabItem { Label("AI Analysis", systemImage: "brain") }
            
            NavigationStack {
                SUIFinancialDashboardView(coordinator: coordinator)
            }
            .tabItem { Label("Metrics", systemImage: "chart.bar.fill") }
        }
        .environmentObject(coordinator.watchListManager)
        .environmentObject(coordinator.roicManager)
        .environmentObject(coordinator.epsGrowthManager)
        .environmentObject(coordinator.salesGrowthManager)
        .environmentObject(coordinator.equityGrowthManager)
        .environmentObject(coordinator.freeCashFlowManager)
    }
}

struct SUIFinancialDashboardView: View {
    let coordinator: AppCoordinator
    @State private var selectedCompany: Company?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var facts: CompanyFacts?
    @State private var showingCompanySelector = false
    
    var body: some View {
        VStack {
            if let company = selectedCompany, let companyFacts = facts {
                MetricsDashboardView(facts: companyFacts)
                    .navigationTitle("\(company.companyTicker) Metrics")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingCompanySelector = true
                            }) {
                                Label("Change Company", systemImage: "arrow.left.arrow.right")
                            }
                        }
                    }
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 70))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Financial Metrics Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select a company to view detailed financial metrics and analysis")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingCompanySelector = true
                    }) {
                        HStack {
                            Image(systemName: "building.2")
                            Text("Select Company")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Financial Dashboard")
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color(.systemBackground).opacity(0.7)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading financial data...")
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingCompanySelector) {
            CompanySelectorView(
                coordinator: coordinator,
                selectedCompany: $selectedCompany,
                onCompanySelected: { company in
                    loadCompanyData(company)
                }
            )
        }
    }
    
    private func loadCompanyData(_ company: Company) {
        isLoading = true
        facts = nil
        
        let networkService = coordinator.serviceFactory.makeCompanyFinancialsNetworkService()
        
        Task {
            do {
                let facts = try await networkService.getCompanyFinancials(cik: company.cik).async()
                await MainActor.run {
                    self.facts = facts
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading data: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

struct CompanySelectorView: View {
    let coordinator: AppCoordinator
    @Binding var selectedCompany: Company?
    let onCompanySelected: (Company) -> Void
    
    @State private var companies: [Company] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var filteredCompanies: [Company] {
        if searchText.isEmpty {
            return companies
        } else {
            return companies.filter {
                $0.companyName.lowercased().contains(searchText.lowercased()) ||
                $0.companyTicker.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    if companies.isEmpty {
                        Text("No companies found")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(filteredCompanies) { company in
                                Button(action: {
                                    selectedCompany = company
                                    onCompanySelected(company)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    CompanyCellView(company: company)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search companies")
            .navigationTitle("Select a Company")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                fetchCompanies()
            }
        }
    }
    
    private func fetchCompanies() {
        isLoading = true
        
        let networkService = coordinator.serviceFactory.makeCentralIndexKeyNetworkService()
        
        Task {
            do {
                let companies = try await networkService.getCompanyTickers().async()
                await MainActor.run {
                    self.companies = companies
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading companies: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

// Helper to convert Publisher to async/await
extension Publisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        cancellable?.cancel()
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}
