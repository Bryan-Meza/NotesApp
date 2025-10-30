//
//  AuthView.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import SwiftUI

/**
 * AuthView - Authentication screen with sign in and sign up
 */
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                inputFieldsSection
                actionButton
                modeToggleSection
                Spacer()
            }
            .padding()
            .navigationTitle(isSignUpMode ? "Create Account" : "Welcome Back")
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    authViewModel.errorMessage = nil
                }
            } message: {
                Text(authViewModel.errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: authViewModel.errorMessage) { _, newValue in
                showError = newValue != nil
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Notes App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isSignUpMode ? "Create your account" : "Sign in to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(isSignUpMode ? .newPassword : .password)
        }
    }
    
    private var actionButton: some View {
        Button(action: handleAuthentication) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Text(isSignUpMode ? "Sign Up" : "Sign In")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!isFormValid || authViewModel.isLoading)
    }
    
    private var modeToggleSection: some View {
        Button(action: {
            withAnimation {
                isSignUpMode.toggle()
            }
        }) {
            HStack {
                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(.secondary)
                
                Text(isSignUpMode ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private func handleAuthentication() {
        Task {
            do {
                if isSignUpMode {
                    try await authViewModel.signUp(email: email, password: password)
                } else {
                    try await authViewModel.signIn(email: email, password: password)
                }
            } catch {
                print("Authentication error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
