//
//  EditNoteView.swift
//  NoteApp
//
//  Created by Bryan Meza on 30/10/25.
//

import SwiftUI

/**
 * EditNoteView - Create or edit a note
 * Uses 'noteBody' to avoid conflict with SwiftUI's 'body' property
 */
struct EditNoteView: View {
    @ObservedObject var notesViewModel: NotesViewModel
    var note: Note?
    
    @State private var title: String
    @State private var noteBody: String  // Renamed to avoid conflict with View's body
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPresentedAsSheet: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    // For sheet presentation
    init(notesViewModel: NotesViewModel, note: Note? = nil, isPresented: Binding<Bool>) {
        self.notesViewModel = notesViewModel
        self.note = note
        self._title = State(initialValue: note?.title ?? "")
        self._noteBody = State(initialValue: note?.body ?? "")
        self._isPresentedAsSheet = State(initialValue: true)
    }
    
    // For NavigationLink presentation
    init(notesViewModel: NotesViewModel, note: Note? = nil) {
        self.notesViewModel = notesViewModel
        self.note = note
        self._title = State(initialValue: note?.title ?? "")
        self._noteBody = State(initialValue: note?.body ?? "")
        self._isPresentedAsSheet = State(initialValue: false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter note title", text: $title)
                }
                
                Section(header: Text("Body")) {
                    TextEditor(text: $noteBody)
                        .frame(minHeight: 200)
                }
                
                if let note = note {
                    Section(header: Text("Details")) {
                        HStack {
                            Text("Created")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(note.createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await handleSave()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isSaving)
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func handleSave() async {
        guard isFormValid else {
            errorMessage = "Please enter a title for your note"
            showError = true
            return
        }
        
        isSaving = true
        
        let success: Bool
        
        if let note = note {
            success = await notesViewModel.updateNote(
                noteId: note.id,
                title: title,
                body: noteBody
            )
        } else {
            success = await notesViewModel.createNote(
                title: title,
                body: noteBody
            )
        }
        
        isSaving = false
        
        if success {
            dismiss()
        } else {
            errorMessage = notesViewModel.errorMessage ?? "Failed to save note"
            showError = true
        }
    }
}

#Preview("Create Note") {
    EditNoteView(
        notesViewModel: NotesViewModel(),
        isPresented: .constant(true)
    )
}
