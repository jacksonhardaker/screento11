import XCTest
@testable import ScreenTo11

final class GainPolicyTests: XCTestCase {
    func testRequestedGainTracksPotential() {
        XCTAssertEqual(GainPolicy.requestedGain(level: 0, potential: 3), 1)
        XCTAssertEqual(GainPolicy.requestedGain(level: 0.5, potential: 3), 2)
        XCTAssertEqual(GainPolicy.requestedGain(level: 1, potential: 3), 3)
    }

    func testCurrentHeadroomAlwaysCapsGain() {
        XCTAssertEqual(GainPolicy.effectiveGain(level: 1, potential: 3, current: 1.4), 1.4)
        XCTAssertEqual(GainPolicy.effectiveGain(level: 0.5, potential: 3, current: 1.4), 1.2)
        XCTAssertEqual(GainPolicy.effectiveGain(level: 1, potential: 3, current: 1), 1)
        XCTAssertEqual(GainPolicy.effectiveGain(level: 1, potential: 3, current: 4), 3)
    }

    func testInvalidInputsCannotRequestExcessGain() {
        XCTAssertEqual(GainPolicy.effectiveGain(level: 2, potential: 2, current: 1.5), 1.5)
        XCTAssertEqual(GainPolicy.effectiveGain(level: -1, potential: 2, current: 2), 1)
        XCTAssertEqual(GainPolicy.effectiveGain(level: 1, potential: .infinity, current: 2), 1)
    }
}
