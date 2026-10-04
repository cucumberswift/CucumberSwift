//
//  ParallelFixtureApp.swift
//  ParallelFixtures
//
//  The app the parallel fixtures' hosted unit tests run in and their UI tests drive: a cart that counts the
//  items added to it. The same code builds for iOS, Mac Catalyst, tvOS and macOS.
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
