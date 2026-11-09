//
//  CucumberSwiftTestingInterop.c
//  CucumberSwiftTestingInterop
//

#include "CucumberSwiftTestingInterop.h"
#include <stdlib.h>

/// Runs when the test bundle loads, before XCTest reads SWIFT_TESTING_XCTEST_INTEROP_MODE, which it does
/// once, as it starts. In "complete" mode a failed `XCTAssert` fails the Swift Testing test that runs it,
/// so it fails its step, as a failed `#expect` does. An environment that sets a mode keeps it. Swift can't
/// run code when an image loads, so this is C. Xcode versions without the interop never read the variable.
__attribute__((constructor)) static void cucumberswift_enable_xctest_interop(void) {
    setenv("SWIFT_TESTING_XCTEST_INTEROP_MODE", "complete", 0);
}

void cucumberswift_testing_interop_linked(void) {}
