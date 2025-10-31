//
//  OfflineNotesRepository.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import SwiftData
import Combine
import SwiftUI  // Add this import

@MainActor
class OfflineNotesRepository: ObservableObject {
    @Published var notes: [LocalNote] = []
    
    private let modelContext: ModelContext
    private let syncManager: SyncManager
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncManager = SyncManager(modelContext: modelContext)
        fetchLocalNotes()
        
        // Subscribe to sync manager updates
        syncManager.$isOnline
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        syncManager.$isSyncing
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func fetchLocalNotes() {
        let descriptor = FetchDescriptor<LocalNote>(
            predicate: #Predicate { !$0.isDeleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let fetchedNotes = try modelContext.fetch(descriptor)
            
            // Use animation for smooth transitions
            withAnimation(.easeInOut(duration: 0.3)) {
                notes = fetchedNotes
            }
            
            print("📋 Fetched \(notes.count) local notes")
        } catch {
            print("❌ Fetch failed: \(error)")
            notes = []
        }
    }
    
    func createNote(userId: String, title: String, body: String) {
        let note = LocalNote(userId: userId, title: title, body: body, needsSync: true)
        modelContext.insert(note)
        
        do {
            try modelContext.save()
            print("✅ Note created locally: \(title)")
            fetchLocalNotes()
            
            Task {
                await syncManager.syncAll()
                fetchLocalNotes()
            }
        } catch {
            print("❌ Save failed: \(error)")
        }
    }
    
    func updateNote(note: LocalNote, title: String, body: String) {
        note.title = title
        note.body = body
        note.needsSync = true
        note.lastModified = Date()
        
        do {
            try modelContext.save()
            print("✅ Note updated locally: \(title)")
            fetchLocalNotes()
            
            Task {
                await syncManager.syncAll()
                fetchLocalNotes()
            }
        } catch {
            print("❌ Update failed: \(error)")
        }
    }
    
    func deleteNote(note: LocalNote) {
        if note.isSynced {
            note.isDeleted = true
            note.needsSync = true
        } else {
            modelContext.delete(note)
        }
        
        do {
            try modelContext.save()
            print("✅ Note deleted locally")
            fetchLocalNotes()
            
            Task {
                await syncManager.syncAll()
                fetchLocalNotes()
            }
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
    
    func searchNotes(term: String) {
        if term.isEmpty {
            fetchLocalNotes()
            return
        }
        
        let descriptor = FetchDescriptor<LocalNote>(
            predicate: #Predicate { note in
                !note.isDeleted &&
                (note.title.localizedStandardContains(term) ||
                 note.body.localizedStandardContains(term))
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let searchResults = try modelContext.fetch(descriptor)
            withAnimation {
                notes = searchResults
            }
        } catch {
            print("❌ Search failed: \(error)")
        }
    }
    
    func manualSync() async {
        await syncManager.syncAll()
        fetchLocalNotes()
    }
    
    func clearAllLocalData() {
        let descriptor = FetchDescriptor<LocalNote>()
        
        do {
            let allNotes = try modelContext.fetch(descriptor)
            for note in allNotes {
                modelContext.delete(note)
            }
            try modelContext.save()
            fetchLocalNotes()
            print("🗑️ Cleared all local notes")
        } catch {
            print("❌ Clear failed: \(error)")
        }
    }
    
    var isOnline: Bool { syncManager.isOnline }
    var isSyncing: Bool { syncManager.isSyncing }
}
