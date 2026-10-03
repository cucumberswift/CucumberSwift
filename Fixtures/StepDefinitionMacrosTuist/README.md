# Step definition macros in a Tuist project

Uses the step definition macros from an Xcode project that Tuist generates: CucumberSwift in
`Project.packages` with `traits: ["Macros"]`, and the `CucumberSwiftMacros` product.

The step definitions only compile when the trait reaches Xcode. Xcode 26.4 and later apply a
package's traits in an Xcode project; an earlier Xcode ignores them, and each macro then reports
that the `Macros` trait has to be turned on.

Needs Xcode 26.4 or later, and the Tuist version pinned in `.mise.toml`. Run every fixture with
`mise run test-fixtures`.
