//
//  NoteAppApp.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//

import SwiftUI
import SwiftData

@main
struct NoteAppApp: App {
    // SwiftData container
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: LocalNote.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthViewModel())
                .modelContainer(modelContainer)
        }
    }
}
