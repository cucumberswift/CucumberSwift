//
//  Shop.swift
//  ParityShop
//
//  The code the parity scenarios test, and the code CucumberSwift measures when coverage is on. The
//  Coverage feature runs only some of `price(of:)`'s branches, so its scores are below 100%.
//

public enum Shop {
    /// The price of one item, in cents. An item the shop doesn't sell costs nothing.
    public static func price(of item: String) -> Int {
        switch item {
            case "cuke": return 50
            case "tomato": return 30
            case "lettuce": return 120
            case "pepper": return 80
            default: return 0
        }
    }
}

/// A basket the scenarios fill in, one per scenario.
public final class Basket {
    public private(set) var items: [String: Int] = [:]

    public init() {}

    public func add(_ count: Int, of item: String) {
        items[item, default: 0] += count
    }

    public var total: Int {
        items.reduce(0) { $0 + Shop.price(of: $1.key) * $1.value }
    }
}
