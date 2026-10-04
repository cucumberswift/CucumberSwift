# CucumberSwift from Carthage

Uses CucumberSwift as a project that installs it with Carthage does: an iOS test target that links
`Carthage/Build/CucumberSwift.xcframework` and copies it into its Frameworks folder, and has
`$(BUILT_PRODUCTS_DIR)/CucumberSwift.framework/Modules` in `SWIFT_INCLUDE_PATHS`. Its step
definitions use Cucumber expressions with typed parameters, and import only CucumberSwift, with
`MemberImportVisibility` on as in Xcode 26's app template.

They compile only when the CucumberSwiftExpressions module ships inside the framework and
CucumberSwift re-exports it. The build folder Carthage used is deleted first: the framework's
module records its search paths, so a test on the machine that built it would otherwise find the
module there and pass.

`mise run test-carthage` builds the framework with Carthage and runs this fixture on an iOS
simulator. `mise run test-fixtures` skips it. Needs Carthage 0.37 or later, and the Tuist version
pinned in `.mise.toml`.
