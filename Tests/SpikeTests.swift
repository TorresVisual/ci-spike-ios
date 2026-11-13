import XCTest

final class SpikeTests: XCTestCase {
    func testRustCoreSelftest() { XCTAssertEqual(spike_selftest(), 1) }
}
