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
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("RembrandtPugIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .clipShape(Circle())
                
                Text("MUNGER.AI")
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
                    print("🔍 Sign-in attempt with email: \(email)")
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
                Button("Forgot Password?") {
                    showingPasswordReset = true
                }
                .sheet(isPresented: $showingPasswordReset) {
                    SUIPasswordResetView()
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let factory = ServiceFactory()
    let coordinator = AppCoordinator(serviceFactory: factory)
    SUIAuthenticationView()
        .environmentObject(coordinator.authViewModel)
}
