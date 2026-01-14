//
//  EntryView.swift
//  Humanjournal
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
private let platformBackground = UIColor.systemBackground
#elseif os(macOS)
private let platformBackground = NSColor.windowBackgroundColor
#endif

struct EntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var isSaving = false
    @State private var hasUnsavedChanges = false
    @FocusState private var isTextEditorFocused: Bool

    let date: Date
    let existingContent: String?
    let onSave: (String) async -> Void

    init(date: Date = Date(), existingContent: String? = nil, onSave: @escaping (String) async -> Void) {
        self.date = date
        self.existingContent = existingContent
        self.onSave = onSave
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasUnsavedChanges
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateHeader

                textEditor
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .onAppear {
                if let existing = existingContent {
                    content = existing
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true
                }
            }
            .onChange(of: content) { _, _ in
                hasUnsavedChanges = content != (existingContent ?? "")
            }
        }
    }

    private var dateHeader: some View {
        Text(formattedDate)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var textEditor: some View {
        TextEditor(text: $content)
            .focused($isTextEditorFocused)
            .font(.body)
            .padding(.horizontal, 12)
            .scrollContentBackground(.hidden)
            .background(Color(platformBackground))
    }

    private var saveButton: some View {
        Button {
            Task {
                await save()
            }
        } label: {
            if isSaving {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Text("Save")
                    .fontWeight(.semibold)
            }
        }
        .disabled(!canSave || isSaving)
    }

    private func save() async {
        guard canSave else { return }

        isSaving = true

        await onSave(content)

        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif

        hasUnsavedChanges = false
        isSaving = false

        dismiss()
    }
}

#Preview {
    EntryView { content in
        print("Saved: \(content)")
    }
}
