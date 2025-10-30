//
//  SessionViewModel.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import Foundation
import Combine
import Supabase
import Auth

@MainActor
final class SessionViewModel: ObservableObject {
  @Published var isSignedIn = false
  private var watcher: Task<Void, Never>?

  init() {
    watcher = Task { await observeAuth() }
  }

  deinit { watcher?.cancel() }

  private func observeAuth() async {
    // Initial state: check if there is a stored session
    let hasSession = (try? await supabase.auth.session) != nil
    self.isSignedIn = hasSession

    // React to future changes
    for await change in supabase.auth.authStateChanges {
      switch change.event {
      case .initialSession, .signedIn, .tokenRefreshed:
        self.isSignedIn = true
      case .signedOut, .userDeleted:
        self.isSignedIn = false
      default:
        break
      }
    }
  }

  func signOut() async {
    do { try await supabase.auth.signOut() } catch { }
  }
}

