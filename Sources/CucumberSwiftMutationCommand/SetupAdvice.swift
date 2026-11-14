//
//  SetupAdvice.swift
//  CucumberSwiftMutationCommand
//

/// What the command prints when CucumberSwift's Macros trait is off, so the tool can't read Swift code.
enum SetupAdvice {
    static let traitOffMessage = """
        Mutation testing needs CucumberSwift's Macros package trait, which brings in swift-syntax, and changed nothing.
        Turn the trait on in the package that depends on CucumberSwift, then run the command again.
        "Checking Step Definitions When They Compile" in the documentation has the details.

        """
}
