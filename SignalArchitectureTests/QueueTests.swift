import XCTest
@testable import SignalArchitecture

class QueueTests: XCTestCase {
  let mainQueue = Queue.main
  let backgroudQueue = Queue.background

  func testMainAsyncIsActuallyAsyncOnMain() {
    var shouldBe4AndThen5 = 4

    let willCallTheFirstAsync = expectationWithDescription("willCallTheFirstAsync")
    mainQueue.async {
      shouldBe4AndThen5 = 5
      willCallTheFirstAsync.fulfill()
    }

    XCTAssertEqual(shouldBe4AndThen5, 4)

    let willCallTheSecondAsync = expectationWithDescription("willCallTheSecondAsync")
    mainQueue.async {
      XCTAssertEqual(shouldBe4AndThen5, 5)
      willCallTheSecondAsync.fulfill()
    }

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testBackgroundAsyncIsActuallySyncOnMain() {
    var shouldBe5 = 4

    let willCallTheFirstAsync = expectationWithDescription("willCallTheFirstAsync")
    backgroudQueue.async {
      shouldBe5 = 5
      willCallTheFirstAsync.fulfill()
    }

    XCTAssertEqual(shouldBe5, 5)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testBackgroundSyncIsActuallySyncOnMain() {
    var shouldBe5 = 4

    let willCallTheFirstAsync = expectationWithDescription("willCallTheFirstAsync")
    backgroudQueue.sync {
      shouldBe5 = 5
      willCallTheFirstAsync.fulfill()
    }

    XCTAssertEqual(shouldBe5, 5)

    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
