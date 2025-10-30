//
//  RootView.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import SwiftUI

/**
 * RootView - Root navigation that switches between auth and main app
 */
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.session != nil {
                NotesListView()
            } else {
                AuthView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
