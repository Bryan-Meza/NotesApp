//
//  AuthViewModel.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import Supabase
import SwiftUI
import Combine  // Add this import

/**
 * AuthViewModel - Manages authentication state and operations
 */
@MainActor
class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientManager.shared.client) {
        self.client = client
        
        Task {
            await checkSession()
        }
        
        Task {
            for await state in client.auth.authStateChanges {
                self.session = state.session
                self.currentUser = state.session?.user
            }
        }
    }
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.session = session
            self.currentUser = session.user
        } catch {
            self.session = nil
            self.currentUser = nil
        }
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            if let session = response.session {
                self.session = session
                self.currentUser = session.user
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.session = session
            self.currentUser = session.user
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            self.session = nil
            self.currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    var isAuthenticated: Bool {
        session != nil
    }
}
