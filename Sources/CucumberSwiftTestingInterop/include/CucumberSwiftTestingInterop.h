//
//  CucumberSwiftTestingInterop.h
//  CucumberSwiftTestingInterop
//

#ifndef CucumberSwiftTestingInterop_h
#define CucumberSwiftTestingInterop_h

/// Does nothing. CucumberSwiftTesting calls it so that the linker keeps this target's object file, whose
/// constructor turns on XCTest's interop with Swift Testing when the test bundle loads.
void cucumberswift_testing_interop_linked(void);

#endif
