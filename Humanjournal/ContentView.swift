//
//  ContentView.swift
//  Humanjournal
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "book.closed")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Humanjournal")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
