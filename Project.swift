import ProjectDescription

// MARK: - Shared values lifted from the committed CucumberSwift.xcodeproj
//
// This manifest reproduces CucumberSwift.xcodeproj one setting at a time so the
// generated project can be compared against the committed one before the
// committed one is removed. Every value below has a counterpart in
// project.pbxproj; nothing is left to a Tuist default.

let developmentTeam = "9CUJHB48U6"
let runpathSearchPaths: SettingValue = [
    "$(inherited)",
    "@executable_path/Frameworks",
    "@loader_path/Frameworks"
]

// MARK: - Project level settings (XCConfigurationList for PBXProject "CucumberSwift")

let projectBaseSettings: SettingsDictionary = [
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++14",
    "CLANG_CXX_LIBRARY": "libc++",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "CODE_SIGN_IDENTITY": "iPhone Developer",
    "COPY_PHASE_STRIP": "NO",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu11",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    // The project level floor is 12.0; every target raises it to 13.0 below.
    "IPHONEOS_DEPLOYMENT_TARGET": "12.0",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "5.0",
    "VERSIONING_SYSTEM": "apple-generic",
    "VERSION_INFO_PREFIX": ""
]

let projectDebugSettings: SettingsDictionary = [
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "YES",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
]

let projectReleaseSettings: SettingsDictionary = [
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": "-O",
    "VALIDATE_PRODUCT": "YES"
]

// MARK: - SwiftLint run script (PBXShellScriptBuildPhase "Lint")

let lintScript = TargetScript.post(
    script: """
    export PATH="$PATH:/opt/homebrew/bin"

    if which swiftlint > /dev/null; then
      swiftlint --config .swiftlint.yml
    else
      echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    fi
    """,
    name: "Lint",
    basedOnDependencyAnalysis: false
)

// MARK: - Targets

let cucumberSwift = Target.target(
    name: "CucumberSwift",
    destinations: [.iPhone, .iPad],
    product: .framework,
    bundleId: "TylerThompson.CucumberSwift",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .file(path: "Sources/CucumberSwift/Info.plist"),
    sources: [
        // The .docc catalog carries two sample .swift files that are documentation
        // resources, not compiled sources. They are excluded here, exactly as the
        // committed Sources build phase excludes them.
        .glob(
            "Sources/CucumberSwift/**/*.swift",
            excluding: ["Sources/CucumberSwift/CucumberSwift.docc/**"]
        ),
        "Sources/CucumberSwift/CucumberSwift.docc"
    ],
    resources: [".swiftlint.yml"],
    scripts: [lintScript],
    dependencies: [
        .package(product: "CucumberSwiftExpressions"),
        .xctest
    ],
    settings: .settings(
        base: [
            "CLANG_ENABLE_MODULES": "YES",
            "CODE_SIGN_IDENTITY": "",
            "CODE_SIGN_STYLE": "Automatic",
            "DEFINES_MODULE": "YES",
            "DEVELOPMENT_TEAM": .string(developmentTeam),
            "DYLIB_COMPATIBILITY_VERSION": "1",
            "DYLIB_CURRENT_VERSION": "1",
            "DYLIB_INSTALL_NAME_BASE": "@rpath",
            "ENABLE_BITCODE": "NO",
            "FRAMEWORK_SEARCH_PATHS": "$(PLATFORM_DIR)/Developer/Library/Frameworks",
            "INSTALL_PATH": "$(LOCAL_LIBRARY_DIR)/Frameworks",
            "LD_RUNPATH_SEARCH_PATHS": runpathSearchPaths,
            "PRODUCT_NAME": "$(TARGET_NAME:c99extidentifier)",
            "SKIP_INSTALL": "YES",
            "SWIFT_OBJC_BRIDGING_HEADER": "",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2"
        ],
        configurations: [
            .debug(name: .debug, settings: ["SWIFT_OPTIMIZATION_LEVEL": "-Onone"]),
            .release(name: .release)
        ],
        defaultSettings: .none
    )
)

let cucumberSwiftTests = Target.target(
    name: "CucumberSwiftTests",
    destinations: [.iPhone, .iPad],
    product: .unitTests,
    bundleId: "Tyler.Thompson.CucumberSwiftTests",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .file(path: "Tests/CucumberSwiftTests/Info.plist"),
    sources: ["Tests/CucumberSwiftTests/**/*.swift"],
    resources: [
        "Tests/CucumberSwiftTests/Reporter/Schema.json",
        // Features and testdata are folder references in the committed project.
        // They keep their directory structure inside the test bundle.
        .folderReference(path: "Tests/CucumberSwiftTests/Features"),
        .folderReference(path: "Tests/CucumberSwiftTests/testdata")
    ],
    dependencies: [
        .target(name: "CucumberSwift"),
        .package(product: "CucumberSwiftExpressions"),
        .package(product: "JSONSchema")
    ],
    settings: .settings(
        base: [
            "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": "YES",
            "CODE_SIGN_IDENTITY": "Apple Development",
            "CODE_SIGN_IDENTITY[sdk=macosx*]": "Apple Development",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": .string(developmentTeam),
            "LD_RUNPATH_SEARCH_PATHS": runpathSearchPaths,
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "PROVISIONING_PROFILE_SPECIFIER": "",
            "PROVISIONING_PROFILE_SPECIFIER[sdk=macosx*]": "",
            "TARGETED_DEVICE_FAMILY": "1,2"
        ],
        defaultSettings: .none
    ),
    additionalFiles: ["Tests/CucumberSwiftTests/CucumberTests/CucumberSwift.xctestplan"]
)

let cucumberSwiftConsumerTests = Target.target(
    name: "CucumberSwiftConsumerTests",
    destinations: [.iPhone, .iPad],
    product: .unitTests,
    bundleId: "dignityhealth.CucumberSwiftConsumerTests",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .file(path: "Tests/CucumberSwiftConsumerTests/Info.plist"),
    sources: ["Tests/CucumberSwiftConsumerTests/**/*.swift"],
    resources: [.folderReference(path: "Tests/CucumberSwiftConsumerTests/Features")],
    dependencies: [
        .target(name: "CucumberSwift"),
        .package(product: "CucumberSwiftExpressions")
    ],
    settings: .settings(
        base: [
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
            "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": .string(developmentTeam),
            "LD_RUNPATH_SEARCH_PATHS": runpathSearchPaths,
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "TARGETED_DEVICE_FAMILY": "1,2"
        ],
        defaultSettings: .none
    )
)

let cucumberSwiftDSLConsumerTests = Target.target(
    name: "CucumberSwiftDSLConsumerTests",
    destinations: [.iPhone, .iPad],
    product: .unitTests,
    bundleId: "TT.CucumberSwiftDSLConsumerTests",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .file(path: "Tests/CucumberSwiftDSLConsumerTests/Info.plist"),
    sources: ["Tests/CucumberSwiftDSLConsumerTests/**/*.swift"],
    dependencies: [.target(name: "CucumberSwift")],
    settings: .settings(
        base: [
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": .string(developmentTeam),
            "LD_RUNPATH_SEARCH_PATHS": runpathSearchPaths,
            "MTL_FAST_MATH": "YES",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2"
        ],
        configurations: [
            .debug(name: .debug, settings: ["MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE"]),
            .release(name: .release)
        ],
        defaultSettings: .none
    )
)

// MARK: - Schemes
//
// These three names are load bearing. `fastlane unit_test` runs the CucumberSwift
// scheme and CI runs fastlane, so the names must not drift. Automatic scheme
// generation is switched off in Project.options so no fourth scheme appears.
//
// `shared: true` is not decoration. Carthage clones this repository and builds
// only the schemes shared from the .xcodeproj, so a scheme written to xcuserdata
// instead of xcshareddata/xcschemes is invisible to every Carthage consumer.
// Carthage has no hook that would let it run `tuist generate` first, which is
// also why the generated project stays in version control. See CONTRIBUTING.md.

let cucumberSwiftScheme = Scheme.scheme(
    name: "CucumberSwift",
    shared: true,
    buildAction: .buildAction(targets: ["CucumberSwift"]),
    testAction: .testPlans(
        ["Tests/CucumberSwiftTests/CucumberTests/CucumberSwift.xctestplan"],
        configuration: .debug
    ),
    runAction: .runAction(configuration: .debug),
    archiveAction: .archiveAction(configuration: .release),
    profileAction: .profileAction(configuration: .release),
    analyzeAction: .analyzeAction(configuration: .debug)
)

let consumerTestsScheme = Scheme.scheme(
    name: "CucumberSwiftConsumerTests",
    shared: true,
    buildAction: .buildAction(targets: ["CucumberSwiftConsumerTests"]),
    testAction: .targets(
        [.testableTarget(target: "CucumberSwiftConsumerTests")],
        configuration: .debug
    ),
    runAction: .runAction(configuration: .debug),
    archiveAction: .archiveAction(configuration: .release),
    profileAction: .profileAction(configuration: .release),
    analyzeAction: .analyzeAction(configuration: .debug)
)

let dslConsumerTestsScheme = Scheme.scheme(
    name: "CucumberSwiftDSLConsumerTests",
    shared: true,
    buildAction: .buildAction(targets: ["CucumberSwiftDSLConsumerTests"]),
    testAction: .targets(
        [.testableTarget(target: "CucumberSwiftDSLConsumerTests")],
        configuration: .debug
    ),
    runAction: .runAction(configuration: .debug),
    archiveAction: .archiveAction(configuration: .release),
    profileAction: .profileAction(configuration: .release),
    analyzeAction: .analyzeAction(configuration: .debug)
)

// MARK: - Project

let project = Project(
    name: "CucumberSwift",
    organizationName: "Tyler Thompson",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [
        .remote(
            url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git",
            requirement: .upToNextMajor(from: "0.0.5")
        ),
        .remote(
            url: "https://github.com/kylef/JSONSchema.swift",
            requirement: .upToNextMajor(from: "0.6.0")
        )
    ],
    settings: .settings(
        base: projectBaseSettings,
        configurations: [
            .debug(name: .debug, settings: projectDebugSettings),
            .release(name: .release, settings: projectReleaseSettings)
        ],
        defaultSettings: .none
    ),
    targets: [
        cucumberSwift,
        cucumberSwiftTests,
        cucumberSwiftConsumerTests,
        cucumberSwiftDSLConsumerTests
    ],
    schemes: [
        cucumberSwiftScheme,
        consumerTestsScheme,
        dslConsumerTestsScheme
    ]
)
