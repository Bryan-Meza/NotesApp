//
//  DI.swift
//  NoteApp
//
//  Created by Bryan Meza on 29/10/25.
//

import Foundation
import Supabase

class SupabaseClientManager {
    static let shared = SupabaseClientManager()
    
    let client: SupabaseClient
    
    private init() {
        // Use Config instead of hardcoded values
        let supabaseURL = URL(string: Config.supabaseURL)!
        let supabaseKey = Config.supabaseKey
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
