//
//  SUICompanyFilingsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/10/25.
//

import SwiftUI
import WebKit

struct SUICompanyFilingsView: View {
    @StateObject private var viewModel: CompanyFilingsViewModel
    let company: Company
    
    init(company: Company, coordinator: AppCoordinator) {
        self.company = company
        _viewModel = StateObject(wrappedValue: coordinator.companyFilingsViewModel)
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ErrorView(message: error.localizedDescription)
            } else if viewModel.filings.isEmpty {
                FilingEmptyStateView()
            } else {
                FilingsList(viewModel: viewModel)
            }
        }
        .navigationTitle("\(company.companyTicker) Filings")
        .onAppear {
            viewModel.fetchFilings(cik: company.cik)
        }
    }
}

struct FilingsList: View {
    @ObservedObject var viewModel: CompanyFilingsViewModel
    
    var body: some View {
        List(viewModel.filings, id: \.accessionNumber) { filing in
            NavigationLink(destination: FilingWebViewer(url: filing.documentUrl)) {
                FilingRow(filing: filing)
            }
        }
    }
}

struct FilingRow: View {
    let filing: Filing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Form \(filing.form)")
                .font(.headline)
            Text("Filed: \(formatDate(filing.filingDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !filing.items.isEmpty {
                Text("Items: \(filing.items)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FilingWebViewer: View {
    let url: String
    
    var body: some View {
        WebView(url: URL(string: url)!)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

struct FilingEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Filings Available")
                .font(.headline)
            Text("Pull to refresh to load filings")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
