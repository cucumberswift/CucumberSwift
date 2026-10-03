//
//  BasketApp.swift
//  SwiftTestingAndXCTestTuist
//
//  The app under test: a basket of cukes. Its unit tests check `Basket`, and its UI tests tap the buttons.
//

import SwiftUI

/// What the app shows: how many cukes are in the basket.
struct Basket {
    struct NotEnoughCukes: Error {}

    private(set) var cukes = 0

    mutating func add(_ count: Int) {
        cukes += count
    }

    mutating func remove(_ count: Int) throws {
        guard count <= cukes else { throw NotEnoughCukes() }
        cukes -= count
    }
}

struct BasketView: View {
    @State private var basket = Basket()

    var body: some View {
        VStack(spacing: 20) {
            Text("Cukes: \(basket.cukes)")
                .accessibilityIdentifier("cukes")
            Button("Add") { basket.add(1) }
                .accessibilityIdentifier("add")
            Button("Remove") { try? basket.remove(1) }
                .accessibilityIdentifier("remove")
        }
        .padding()
    }
}

@main
struct BasketApp: App {
    var body: some Scene {
        WindowGroup {
            BasketView()
        }
    }
}
