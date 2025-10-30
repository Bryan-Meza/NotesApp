//
//  Note.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//

import Foundation

/**
 * Note - Data model matching your Supabase table structure
 */
struct Note: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var title: String
    var body: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case body
        case createdAt = "created_at"
    }
    
    // Custom date decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        
        // Handle different date formats
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString) ?? Date()
            }
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    // For creating notes
    init(id: UUID, userId: UUID, title: String, body: String, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.createdAt = createdAt
    }
}

/**
 * CreateNoteDTO - Data transfer object for creating new notes
 */
struct CreateNoteDTO: Encodable {
    let title: String
    let body: String
}

/**
 * UpdateNoteDTO - Data transfer object for updating notes
 */
struct UpdateNoteDTO: Encodable {
    let title: String
    let body: String
}
