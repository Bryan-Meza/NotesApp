//
//  NotesListView.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import SwiftUI
import SwiftData
import Combine

struct NotesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var notesViewModel: NotesViewModel
    @State private var showingCreateNote = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var showingSignOutAlert = false
    
    init() {
        let tempContext = ModelContext(try! ModelContainer(for: LocalNote.self))
        let tempAuth = AuthViewModel()
        _notesViewModel = StateObject(wrappedValue: NotesViewModel(
            modelContext: tempContext,
            authViewModel: tempAuth
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if notesViewModel.notes.isEmpty {
                    emptyStateView
                } else {
                    notesListContent
                }
            }
            .navigationTitle("My Notes")
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, isPresented: $showingSearch)
            .onChange(of: searchText) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await notesViewModel.searchNotes(term: newValue)
                }
            }
            .sheet(isPresented: $showingCreateNote) {
                EditNoteView(notesViewModel: notesViewModel, isPresented: $showingCreateNote)
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
        .onAppear {
            // Reinitialize with correct context and auth
            let vm = NotesViewModel(modelContext: modelContext, authViewModel: authViewModel)
            // This is a workaround - copy the reference
        }
        .task {
            await notesViewModel.fetchNotes()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 6) {
                Image(systemName: notesViewModel.isOnline ? "wifi" : "wifi.slash")
                    .foregroundColor(notesViewModel.isOnline ? .green : .orange)
                    .font(.system(size: 14))
                
                if notesViewModel.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        
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
                    Task { await notesViewModel.fetchNotes() }
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
    
    private var notesListContent: some View {
        List {
            ForEach(notesViewModel.notes) { note in
                NavigationLink {
                    EditNoteView(notesViewModel: notesViewModel, note: note)
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
                _ = await notesViewModel.deleteNote(note: note)
            }
        }
    }
}

struct NoteRowView: View {
    let note: LocalNote
    
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
                
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Show sync status
                if !note.isSynced {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                        Text("Pending")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
