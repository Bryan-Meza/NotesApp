//
//  LocalNote.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import SwiftData

/**
 * LocalNote - SwiftData model for offline storage
 *
 * This is the local version that syncs with Supabase
 */
@Model
class LocalNote {
    @Attribute(.unique) var id: UUID
    var userId: String
    var title: String
    var body: String
    var createdAt: Date
    
    // Sync status
    var isSynced: Bool
    var needsSync: Bool
    var isDeleted: Bool  // For handling deletions
    var lastModified: Date
    
    init(id: UUID = UUID(),
         userId: String,
         title: String,
         body: String,
         createdAt: Date = Date(),
         isSynced: Bool = false,
         needsSync: Bool = true,
         isDeleted: Bool = false,
         lastModified: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isSynced = isSynced
        self.needsSync = needsSync
        self.isDeleted = isDeleted
        self.lastModified = lastModified
    }
    
    // Convert to Supabase Note
    func toNote() -> Note {
        return Note(
            id: id,
            userId: UUID(uuidString: userId) ?? UUID(),
            title: title,
            body: body,
            createdAt: createdAt
        )
    }
}
