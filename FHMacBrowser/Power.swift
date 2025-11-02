import Foundation
import IOKit.pwr_mgt

@MainActor
enum Power {
    private static var assertionID: IOPMAssertionID = 0

    static func keepAwakeOn() {
        IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                    "FHMacBrowser Active" as CFString,
                                    &assertionID)
    }

    static func keepAwakeOff() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
