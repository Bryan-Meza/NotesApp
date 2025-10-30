import Foundation

protocol NotesRepository {
  func fetchNotes() async throws -> [Note]
  func addNote(title: String, body: String?) async throws -> Note
  func updateNote(_ note: Note, title: String, body: String?) async throws -> Note
  func deleteNote(_ note: Note) async throws
}
