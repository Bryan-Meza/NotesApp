//
//  SupabaseNotesRepository.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//

import Foundation
import Supabase

/**
 * SupabaseNotesRepository - Handles all database operations for notes
 */
class SupabaseNotesRepository {
    private let client: SupabaseClient
    private let decoder: JSONDecoder
    
    init(client: SupabaseClient = SupabaseClientManager.shared.client) {
        self.client = client
        
        // Configure JSON decoder for date handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /**
     * Fetch all notes for the current user
     */
    func fetchNotes() async throws -> [Note] {
        let response = try await client
            .from("notes")
            .select()
            .order("created_at", ascending: false)
            .execute()
        
        let notes: [Note] = try decoder.decode(
            [Note].self,
            from: response.data
        )
        
        return notes
    }
    
    /**
     * Create a new note
     */
    func createNote(title: String, body: String) async throws -> Note {
        let dto = CreateNoteDTO(title: title, body: body)
        
        let response = try await client
            .from("notes")
            .insert(dto)
            .select()
            .single()
            .execute()
        
        // Debug: Print the raw response
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        
        let note: Note = try decoder.decode(
            Note.self,
            from: response.data
        )
        
        return note
    }
    
    /**
     * Update an existing note
     */
    func updateNote(noteId: UUID, title: String, body: String) async throws -> Note {
        let dto = UpdateNoteDTO(title: title, body: body)
        
        let response = try await client
            .from("notes")
            .update(dto)
            .eq("id", value: noteId.uuidString)
            .select()
            .single()
            .execute()
        
        let note: Note = try decoder.decode(
            Note.self,
            from: response.data
        )
        
        return note
    }
    
    /**
     * Delete a note
     */
    func deleteNote(noteId: UUID) async throws {
        try await client
            .from("notes")
            .delete()
            .eq("id", value: noteId.uuidString)
            .execute()
    }
    
    /**
     * Search notes by title or body
     */
    func searchNotes(searchTerm: String) async throws -> [Note] {
        let pattern = "%\(searchTerm)%"
        
        let response = try await client
            .from("notes")
            .select()
            .or("title.ilike.\(pattern),body.ilike.\(pattern)")
            .order("created_at", ascending: false)
            .execute()
        
        let notes: [Note] = try decoder.decode(
            [Note].self,
            from: response.data
        )
        
        return notes
    }
}
