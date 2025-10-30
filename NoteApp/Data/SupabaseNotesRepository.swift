//
//  SupabaseNotesRepository.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//


import Foundation
import Supabase
import Postgrest
import Auth

final class SupabaseNotesRepository: NotesRepository {

  func fetchNotes() async throws -> [Note] {
    // throws if no session
    _ = try await supabase.auth.session

    return try await supabase
      .from("notes")
      .select()
      .order("created_at", ascending: false)
      .execute()
      .value
  }

  func addNote(title: String, body: String?) async throws -> Note {
    let session = try await supabase.auth.session
    let payload = NewNote(user_id: session.user.id, title: title, body: body)

    let inserted: [Note] = try await supabase
      .from("notes")
      .insert(payload)
      .select()
      .execute()
      .value

    guard let first = inserted.first else {
      throw NSError(domain: "Notes", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insert returned empty"])
    }
    return first
  }

  func updateNote(_ note: Note, title: String, body: String?) async throws -> Note {
    let payload = UpdateNote(title: title, body: body)
    let updated: [Note] = try await supabase
      .from("notes")
      .update(payload)
      .eq("id", note.id.uuidString)
      .select()
      .execute()
      .value
    return updated.first ?? note
  }

  func deleteNote(_ note: Note) async throws {
    _ = try await supabase
      .from("notes")
      .delete()
      .eq("id", note.id.uuidString)
      .execute()
  }
}
