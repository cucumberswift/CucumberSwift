//
//  CucumberSwiftMacrosPlugin.swift
//  CucumberSwiftMacrosPlugin
//

#if !Macros
// Without the Macros trait there is no swift-syntax, and nothing to provide. A macro target is an
// executable, so it still needs an entry point to build.
@main
enum CucumberSwiftMacrosPluginWithoutMacros {
    static func main() {
        // Nothing to do: the compiler never runs this plugin without the Macros trait.
    }
}

/// What LocalizedStepDefinitionNames.swift, which this target shares with the lint tool, extends.
struct StepDefinition {}
#else
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CucumberSwiftMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [StepDefinitionMacro.self, HookMacro.self, DSLStepMacro.self, DSLFeatureMacro.self, DSLScenarioMacro.self, DSLPartMacro.self]
}
#endif
