import ProjectDescription

// Tuist configuration for CucumberSwift.
//
// Swift package dependencies use Xcode's own SPM integration, declared in the
// `packages:` array of Project.swift. That keeps the generated project's package
// references byte-identical in shape to the ones in the committed
// CucumberSwift.xcodeproj, so `tuist generate` needs no `tuist install` step.
let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .all,
        swiftVersion: "5.0"
    )
)
