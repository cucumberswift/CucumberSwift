//
//  ParallelFixtureApp.swift
//  ParallelFixtures
//
//  The app the parallel fixtures' hosted unit tests run in and their UI tests drive: a cart that counts the
//  items added to it, and empties. The same code builds for iOS, Mac Catalyst, tvOS and macOS.
//

import SwiftUI

struct CartView: View {
    @State private var items = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Items: \(items)")
                .accessibilityIdentifier("items")
            Button("Add") { items += 1 }
                .accessibilityIdentifier("add")
            // Below Add, so that Add keeps the focus on tvOS when the app starts.
            Button("Empty") { items = 0 }
                .accessibilityIdentifier("empty")
        }
        .padding()
    }
}

@main
struct ParallelFixtureApp: App {
    var body: some Scene {
        WindowGroup {
            CartView()
        }
    }
}
