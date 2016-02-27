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

  func testAfter() {
    var shouldBe4AndThen5 = 4

    let willDoAfter1Second = expectationWithDescription("willDoAfter1Second")
    mainQueue.after(1) {
      shouldBe4AndThen5 = 5
      willDoAfter1Second.fulfill()
    }

    let willExecuteAsync1 = expectationWithDescription("willExecuteAsync1")
    mainQueue.async {
      XCTAssertEqual(shouldBe4AndThen5, 4)
      willExecuteAsync1.fulfill()
    }

    let willExecuteAsync2 = expectationWithDescription("willExecuteAsync2")
    mainQueue.async {
      XCTAssertEqual(shouldBe4AndThen5, 4)
      willExecuteAsync2.fulfill()
    }

    let willExecuteAsync3 = expectationWithDescription("willExecuteAsync3")
    mainQueue.async {
      XCTAssertEqual(shouldBe4AndThen5, 4)
      willExecuteAsync3.fulfill()
    }

    XCTAssertEqual(shouldBe4AndThen5, 4)

    let willDoAfter1AndAHalfSeconds = expectationWithDescription("willDoAfter1AndAHalfSeconds")
    mainQueue.after(1.5) {
      XCTAssertEqual(shouldBe4AndThen5, 5)
      willDoAfter1AndAHalfSeconds.fulfill()
    }

    waitForExpectationsWithTimeout(2, handler: nil)
  }
}
