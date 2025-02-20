//
//  SUIAuthenticationView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/13/25.
//

import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct SUIAuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingPasswordReset = false
    @State private var isFaceIDAvailable = false
    @State private var isLoading = false
    
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
                
                if isLoading {
                    ProgressView("Authenticating...")
                } else {
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
                        isLoading = true
                        authViewModel.signIn(email: email, password: password)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty)
                    /*
                    Button(action: {
                        print("🖲️ Face ID button tapped")
                        isLoading = true
                        authViewModel.signInWithFaceID()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Sign In with Face ID")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isFaceIDAvailable || !KeychainManager.hasCredentials())
                     */
                }
                
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
            .onChange(of: authViewModel.isAuthenticated) { _ in isLoading = false }
            .onAppear {
                let context = LAContext()
                var error: NSError?
                isFaceIDAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                print("👀 Face ID evaluation: available=\(isFaceIDAvailable), error=\(error?.localizedDescription ?? "none"), biometricType=\(context.biometryType == .faceID ? "Face ID" : context.biometryType == .touchID ? "Touch ID" : "None")")
            }
        }
    }
}

#Preview {
    let factory = ServiceFactory()
    let coordinator = AppCoordinator(serviceFactory: factory)
    SUIAuthenticationView()
        .environmentObject(coordinator.authViewModel)
}
