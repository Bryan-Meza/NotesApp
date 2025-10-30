//
//  NoteAppApp.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//

import SwiftUI
import Supabase

/**
 * NoteAppApp - Main entry point for the Notes application
 * Initializes the app and provides the root view with authentication state
 */
@main
struct NoteAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthViewModel())
        }
    }
}
