//
//  NotesViewModel.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import Supabase

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [LocalNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOnline = false
    @Published var isSyncing = false
    
    private let offlineRepository: OfflineNotesRepository
    private let authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, authViewModel: AuthViewModel) {
        self.offlineRepository = OfflineNotesRepository(modelContext: modelContext)
        self.authViewModel = authViewModel
        self.notes = offlineRepository.notes
        self.isOnline = offlineRepository.isOnline
        self.isSyncing = offlineRepository.isSyncing
        
        // Subscribe to repository changes
        offlineRepository.$notes
            .sink { [weak self] newNotes in
                self?.notes = newNotes
            }
            .store(in: &cancellables)
        
        // Monitor connection status
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.isOnline = self?.offlineRepository.isOnline ?? false
                self?.isSyncing = self?.offlineRepository.isSyncing ?? false
            }
            .store(in: &cancellables)
    }
    
    func fetchNotes() async {
        print("🔄 Fetching notes...")
        
        // Load local notes immediately
        offlineRepository.fetchLocalNotes()
        notes = offlineRepository.notes
        
        // Sync with server in background
        await offlineRepository.manualSync()
        
        // Refresh after sync
        offlineRepository.fetchLocalNotes()
        notes = offlineRepository.notes
        
        print("✅ Fetch complete - \(notes.count) notes")
    }
    
    func createNote(title: String, body: String) async -> Bool {
        guard !title.isEmpty else {
            errorMessage = "Title cannot be empty"
            return false
        }
        
        guard let userId = authViewModel.currentUser?.id.uuidString else {
            errorMessage = "Not authenticated"
            return false
        }
        
        print("➕ Creating note: \(title)")
        offlineRepository.createNote(userId: userId, title: title, body: body)
        
        // Force immediate update
        notes = offlineRepository.notes
        print("✅ Note created - now have \(notes.count) notes")
        
        return true
    }
    
    func updateNote(note: LocalNote, title: String, body: String) async -> Bool {
        guard !title.isEmpty else { return false }
        
        print("✏️ Updating note: \(title)")
        offlineRepository.updateNote(note: note, title: title, body: body)
        
        // Force immediate update
        notes = offlineRepository.notes
        print("✅ Note updated")
        
        return true
    }
    
    func deleteNote(note: LocalNote) async -> Bool {
        print("🗑️ Deleting note: \(note.title)")
        offlineRepository.deleteNote(note: note)
        
        // Force immediate update
        notes = offlineRepository.notes
        print("✅ Note deleted - now have \(notes.count) notes")
        
        return true
    }
    
    func searchNotes(term: String) async {
        offlineRepository.searchNotes(term: term)
        notes = offlineRepository.notes
    }
    
    func clearAllData() {
        offlineRepository.clearAllLocalData()
        notes = offlineRepository.notes
    }
}
