//
//  NotesListView.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import SwiftUI
import Combine  // Add this import

/**
 * NotesListView - Displays list of notes with search and actions
 */
struct NotesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var notesViewModel = NotesViewModel()
    
    @State private var showingCreateNote = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if notesViewModel.notes.isEmpty && !notesViewModel.isLoading {
                    emptyStateView
                } else {
                    notesListContent
                }
                
                if notesViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationTitle("My Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await notesViewModel.fetchNotes()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, isPresented: $showingSearch)
            .onChange(of: searchText) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await notesViewModel.searchNotes(term: newValue)
                }
            }
            .sheet(isPresented: $showingCreateNote) {
                EditNoteView(
                    notesViewModel: notesViewModel,
                    isPresented: $showingCreateNote
                )
            }
            .task {
                await notesViewModel.fetchNotes()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var notesListContent: some View {
        List {
            ForEach(notesViewModel.notes) { note in
                NavigationLink {
                    EditNoteView(
                        notesViewModel: notesViewModel,
                        note: note
                    )
                } label: {
                    NoteRowView(note: note)
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await notesViewModel.fetchNotes()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to create your first note")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingCreateNote = true
            } label: {
                Text("Create Note")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let note = notesViewModel.notes[index]
                _ = await notesViewModel.deleteNote(noteId: note.id)
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(note.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotesListView()
        .environmentObject(AuthViewModel())
}
