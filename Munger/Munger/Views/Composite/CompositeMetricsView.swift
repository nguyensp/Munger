//
//  CompositeMetricsView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/26/25.
//

import SwiftUI
import Charts

struct CompositeMetricsView: View {
    let facts: CompanyFacts
    let compositeMetricsService: CompositeMetricsService
    
    @State private var valueCreationScore: Double?
    @State private var financialStrengthScore: Double?
    @State private var fcfConsistencyScore: Double?
    @State private var ruleOf40Score: Double?
    @State private var pegRatio: Double?
    @State private var showingPEInput = false
    @State private var peRatio: String = ""
    
    // Mock stock price - in a real app, you would fetch this from a market data API
    @State private var currentPrice: Double?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Composite Financial Metrics")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 5)
                
                Text("These metrics combine various financial indicators to provide a more holistic view of \(facts.entityName)'s financial performance.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Score cards section
                HStack(spacing: 15) {
                    if let score = valueCreationScore {
                        ScoreCardView(
                            title: "Value Creation",
                            score: score,
                            description: "Measures ability to create shareholder value through ROIC and growth"
                        )
                    }
                    
                    if let score = financialStrengthScore {
                        ScoreCardView(
                            title: "Financial Strength",
                            score: score,
                            description: "Overall financial health assessment"
                        )
                    }
                }
                
                HStack(spacing: 15) {
                    if let score = fcfConsistencyScore {
                        ScoreCardView(
                            title: "FCF Consistency",
                            score: score,
                            description: "Stability of cash flow generation"
                        )
                    }
                    
                    if let score = ruleOf40Score {
                        RuleOf40CardView(score: score)
                    }
                }
                
                // P/E and PEG Ratio Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Price-Based Metrics")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingPEInput = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Enter P/E")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let peg = pegRatio {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("PEG Ratio")
                                    .font(.headline)
                                Text("P/E to Growth")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", peg))
                                .font(.title2)
                                .bold()
                                .foregroundColor(getPEGColor(peg))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Calculate Button
                Button(action: {
                    calculateAllMetrics()
                }) {
                    Text("Calculate All Metrics")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .sheet(isPresented: $showingPEInput) {
            PERatioInputView(peRatio: $peRatio, onSave: {
                if let pe = Double(peRatio), pe > 0 {
                    calculatePEGRatio(pe: pe)
                }
                showingPEInput = false
            })
        }
    }
    
    private func calculateAllMetrics() {
        valueCreationScore = compositeMetricsService.calculateValueCreationScore(companyCik: facts.cik, facts: facts)
        financialStrengthScore = compositeMetricsService.calculateFinancialStrengthScore(companyCik: facts.cik, facts: facts)
        fcfConsistencyScore = compositeMetricsService.calculateFCFConsistencyScore(companyCik: facts.cik, facts: facts)
        ruleOf40Score = compositeMetricsService.calculateRuleOf40(companyCik: facts.cik, facts: facts)
        
        // If we already have a P/E ratio entered, calculate PEG
        if let pe = Double(peRatio), pe > 0 {
            calculatePEGRatio(pe: pe)
        }
    }
    
    private func calculatePEGRatio(pe: Double) {
        pegRatio = compositeMetricsService.calculatePEGRatio(companyCik: facts.cik, facts: facts, currentPE: pe)
    }
    
    private func getPEGColor(_ peg: Double) -> Color {
        switch peg {
        case ..<1:
            return .green
        case 1..<1.5:
            return .yellow
        default:
            return .red
        }
    }
}

struct ScoreCardView: View {
    let title: String
    let score: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(scoreGradient, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Text("\(Int(score))")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(scoreColor)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<70:
            return .yellow
        default:
            return .green
        }
    }
    
    private var scoreGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [scoreColor.opacity(0.2), scoreColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(score * 3.6) // 360 degrees / 100 = 3.6
        )
    }
}

struct RuleOf40CardView: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rule of 40")
                .font(.headline)
            
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: min(1, max(0, score / 80))) // Scale to max of 80
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                    
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                
                VStack(alignment: .leading) {
                    Text(score >= 40 ? "Passes" : "Below")
                        .font(.headline)
                        .foregroundColor(scoreColor)
                    
                    Text("Growth + Profit > 40%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 10)
            }
            
            Text("SaaS/Growth company benchmark")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        switch score {
        case ..<20:
            return .red
        case 20..<40:
            return .yellow
        default:
            return .green
        }
    }
}

struct PERatioInputView: View {
    @Binding var peRatio: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter current P/E Ratio")
                    .font(.headline)
                
                TextField("P/E Ratio (e.g., 20)", text: $peRatio)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text("The P/E ratio is needed to calculate the PEG ratio (P/E to Growth), which helps assess if the stock is fairly valued relative to its growth rate.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Save and Calculate", action: onSave)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .navigationBarTitle("P/E Ratio Input", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
