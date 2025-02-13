//
//  SUIAuthenticationView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import SwiftUI
import FirebaseAuth

struct SUIAuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "building.2")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to Munger")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button("Sign In") {
                    authViewModel.signIn(email: email, password: password)
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)
                
                Button("Create Account") {
                    showingSignUp = true
                }
                .sheet(isPresented: $showingSignUp) {
                    SUISignUpView()
                }
                
                if let error = authViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SUIAuthenticationView()
        .environmentObject(AuthenticationViewModel())
}
