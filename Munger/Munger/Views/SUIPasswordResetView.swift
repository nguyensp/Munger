//
//  SUIPasswordResetView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/17/25.
//

import Foundation
import SwiftUI

struct SUIPasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button("Send Reset Link") {
                        resetPassword()
                    }
                    .disabled(email.isEmpty)
                }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Password Reset", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("sent") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                await authViewModel.resetPassword(email: email)
                alertMessage = "Password reset link has been sent to your email."
                showAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}
