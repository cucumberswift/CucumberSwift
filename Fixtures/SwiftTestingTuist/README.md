# Swift Testing in a Tuist project

Runs feature files with Swift Testing from an Xcode project that Tuist generates: CucumberSwift in
`Project.packages`, the `CucumberSwiftTesting` product, and the `CucumberSwiftTestingPlugin` build
tool plugin, which Xcode runs on the unit test target. The step definitions use the plain DSL, so no
package trait is needed.

If Xcode stops running the plugin, or the generated tests stop compiling or matching their steps, this
fixture fails.

Needs the Tuist version pinned in `.mise.toml`. Run every fixture with `mise run test-fixtures`.
