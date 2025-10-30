//
//  NotesViewModel.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import SwiftUI
import Combine  // Add this import

/**
 * NotesViewModel - Manages notes data and business logic
 */
@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchTerm: String = ""
    
    private let repository: SupabaseNotesRepository
    
    init(repository: SupabaseNotesRepository = SupabaseNotesRepository()) {
        self.repository = repository
    }
    
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notes = try await repository.fetchNotes()
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            print("Error fetching notes: \(error)")
        }
        
        isLoading = false
    }
    
    func createNote(title: String, body: String) async -> Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title cannot be empty"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newNote = try await repository.createNote(title: title, body: body)
            notes.insert(newNote, at: 0)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create note: \(error.localizedDescription)"
            print("Error creating note: \(error)")
            isLoading = false
            return false
        }
    }
    
    func updateNote(noteId: UUID, title: String, body: String) async -> Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title cannot be empty"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedNote = try await repository.updateNote(
                noteId: noteId,
                title: title,
                body: body
            )
            
            if let index = notes.firstIndex(where: { $0.id == noteId }) {
                notes[index] = updatedNote
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update note: \(error.localizedDescription)"
            print("Error updating note: \(error)")
            isLoading = false
            return false
        }
    }
    
    func deleteNote(noteId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await repository.deleteNote(noteId: noteId)
            notes.removeAll { $0.id == noteId }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
            print("Error deleting note: \(error)")
            isLoading = false
            return false
        }
    }
    
    func searchNotes(term: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if term.trimmingCharacters(in: .whitespaces).isEmpty {
                notes = try await repository.fetchNotes()
            } else {
                notes = try await repository.searchNotes(searchTerm: term)
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            print("Error searching notes: \(error)")
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
