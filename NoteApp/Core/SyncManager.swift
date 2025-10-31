//
//  SyncManager.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import SwiftData
import Network
import Combine

@MainActor
class SyncManager: ObservableObject {
    @Published var isOnline = false
    @Published var isSyncing = false
    
    private let modelContext: ModelContext
    private let repository: SupabaseNotesRepository
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init(modelContext: ModelContext, repository: SupabaseNotesRepository = SupabaseNotesRepository()) {
        self.modelContext = modelContext
        self.repository = repository
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let wasOffline = !self.isOnline
                let isNowOnline = path.status == .satisfied
                
                self.isOnline = isNowOnline
                print(isNowOnline ? "📡 Online" : "📵 Offline")
                
                if wasOffline && isNowOnline {
                    print("🔄 Connection restored - auto-syncing...")
                    await self.syncAll()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func syncAll() async {
        guard isOnline else {
            print("📵 Offline - skipping sync")
            return
        }
        
        guard !isSyncing else {
            print("⏭️ Already syncing")
            return
        }
        
        isSyncing = true
        print("🔄 Starting sync...")
        
        do {
            // 1. Upload local changes first
            try await syncLocalToRemote()
            
            // 2. Sync deletions to server
            try await syncDeletions()
            
            // 3. Download from server (this handles server-side deletions)
            try await syncRemoteToLocal()
            
            print("✅ Sync completed")
            
        } catch {
            print("❌ Sync error: \(error.localizedDescription)")
        }
        
        isSyncing = false
    }
    
    private func syncLocalToRemote() async throws {
        let descriptor = FetchDescriptor<LocalNote>(
            predicate: #Predicate { $0.needsSync && !$0.isDeleted }
        )
        
        let notesToSync = try modelContext.fetch(descriptor)
        
        guard !notesToSync.isEmpty else {
            print("  ✓ No local changes to upload")
            return
        }
        
        print("📤 Uploading \(notesToSync.count) notes...")
        
        for localNote in notesToSync {
            do {
                if localNote.isSynced {
                    _ = try await repository.updateNote(
                        noteId: localNote.id,
                        title: localNote.title,
                        body: localNote.body
                    )
                    print("  ✓ Updated: \(localNote.title)")
                } else {
                    let created = try await repository.createNote(
                        title: localNote.title,
                        body: localNote.body
                    )
                    localNote.id = created.id
                    print("  ✓ Created: \(localNote.title)")
                }
                
                localNote.isSynced = true
                localNote.needsSync = false
                
            } catch {
                print("  ✗ Failed: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    private func syncDeletions() async throws {
        let descriptor = FetchDescriptor<LocalNote>(
            predicate: #Predicate { $0.isDeleted && $0.isSynced }
        )
        
        let notesToDelete = try modelContext.fetch(descriptor)
        
        guard !notesToDelete.isEmpty else {
            print("  ✓ No deletions to sync")
            return
        }
        
        print("🗑️ Deleting \(notesToDelete.count) notes from server...")
        
        for localNote in notesToDelete {
            do {
                try await repository.deleteNote(noteId: localNote.id)
                modelContext.delete(localNote)
                print("  ✓ Deleted: \(localNote.title)")
            } catch {
                print("  ✗ Delete failed: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    private func syncRemoteToLocal() async throws {
        print("📥 Downloading from server...")
        
        let remoteNotes = try await repository.fetchNotes()
        print("  Server has \(remoteNotes.count) notes")
        
        // Get all local notes
        let localDescriptor = FetchDescriptor<LocalNote>(
            predicate: #Predicate { !$0.isDeleted }
        )
        let localNotes = try modelContext.fetch(localDescriptor)
        print("  Local has \(localNotes.count) notes")
        
        let localIds = Set(localNotes.map { $0.id })
        let remoteIds = Set(remoteNotes.map { $0.id })
        
        // Case 1: Server is empty - delete all synced local notes
        if remoteNotes.isEmpty {
            print("  🗑️ Server is empty")
            let syncedNotes = localNotes.filter { $0.isSynced && !$0.needsSync }
            if !syncedNotes.isEmpty {
                print("  🗑️ Clearing \(syncedNotes.count) synced local notes")
                for note in syncedNotes {
                    modelContext.delete(note)
                }
                try modelContext.save()
            }
            return
        }
        
        // Case 2: Add new notes from server
        var addedCount = 0
        for remoteNote in remoteNotes where !localIds.contains(remoteNote.id) {
            let localNote = LocalNote(
                id: remoteNote.id,
                userId: remoteNote.userId.uuidString,
                title: remoteNote.title,
                body: remoteNote.body,
                createdAt: remoteNote.createdAt,
                isSynced: true,
                needsSync: false
            )
            modelContext.insert(localNote)
            addedCount += 1
        }
        if addedCount > 0 {
            print("  ✓ Downloaded \(addedCount) new notes")
        }
        
        // Case 3: Delete local notes that no longer exist on server
        var deletedCount = 0
        for localNote in localNotes {
            // Only delete if it was synced and doesn't exist on server
            if localNote.isSynced && !localNote.needsSync && !remoteIds.contains(localNote.id) {
                modelContext.delete(localNote)
                deletedCount += 1
            }
        }
        if deletedCount > 0 {
            print("  🗑️ Removed \(deletedCount) deleted notes")
        }
        
        try modelContext.save()
        print("  ✅ Sync complete")
    }
    
    deinit {
        monitor.cancel()
    }
}

struct TimeoutError: Error {}
