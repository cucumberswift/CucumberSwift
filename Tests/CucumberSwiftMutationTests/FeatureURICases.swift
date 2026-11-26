//
//  FeatureURICases.swift
//
//  Shared with CucumberSwiftTests through a symlink, so that ScenarioID.feature(ofURI:) and
//  MutationReport.feature(ofURI:) are tested against the same cases and so agree.
//

/// Feature file URIs as each platform's test bundle gives them, and the path inside the bundle that both readers
/// must return.
let featureURICases: [(uri: String, feature: String)] = [
    // SwiftPM's resource bundle, as `swift test` builds it.
    ("file:///tmp/Shop_ShopTests.bundle/Features/Basket.feature", "Features/Basket.feature"),
    // iOS, tvOS and watchOS: a flat test bundle.
    ("/Users/me/DerivedData/ShopTests.xctest/Features/Basket.feature", "Features/Basket.feature"),
    // macOS and Mac Catalyst: the test bundle keeps its resources in Contents/Resources.
    ("file:///Users/me/DerivedData/ShopTests.xctest/Contents/Resources/Features/Basket.feature", "Features/Basket.feature"),
    ("/tmp/Shop_ShopTests.bundle/Contents/Resources/Features/Basket.feature", "Features/Basket.feature"),
    // A folder named Contents/Resources inside the features is kept.
    ("/tmp/ShopTests.xctest/Features/Contents/Resources/Basket.feature", "Features/Contents/Resources/Basket.feature"),
    ("file:///tmp/My%20Tests.xctest/Features/My%20Basket.feature", "Features/My Basket.feature"),
    // Neither marker: the whole path.
    ("/tmp/Features/Basket.feature", "/tmp/Features/Basket.feature"),
    // A Swift DSL scenario's feature is its Swift file, which the tests read from the mutation tool's copy of the project:
    // the path from the project's folder, whichever folder the run copied it into.
    ("/private/var/folders/qb/T/cucumberswift-mutation/mutation-copy-24590-E3A1F72F/package/Tests/ShopTests/Basket.swift", "Tests/ShopTests/Basket.swift"),
    ("file:///tmp/mutation-copy-1-0a1b2c3d/package/Tests/My%20Tests/Basket.swift", "Tests/My Tests/Basket.swift"),
    // Not a copy of the tool: the folder is not named as one.
    ("/tmp/mutation-copy/package/Tests/Basket.swift", "/tmp/mutation-copy/package/Tests/Basket.swift")
]
