import XCTest
@testable import SignalArchitecture

class Emitter_SignalTests: XCTestCase {
  var intEmitter = Emitter<Int>(executionQueue: Queue.main)
  var voidEmitter = Emitter<Void>(executionQueue: Queue.main)

  override func setUp() {
    intEmitter = Emitter<Int>(executionQueue: Queue.main)
    voidEmitter = Emitter<Void>(executionQueue: Queue.main)
  }

  func testObserveAndEmit() {
    let expectedValue = 4

    let willObserveSignal = expectationWithDescription("willObserveSignal")
    intEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue)
      willObserveSignal.fulfill()
      return .Continue
    }

    intEmitter.emit(expectedValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testEmitAndObserveTwice() {
    let expectedValue = 4
    var hasObservedOnce = false

    let willObserveSignal1 = expectationWithDescription("willObserveSignal1")
    let willObserveSignal2 = expectationWithDescription("willObserveSignal2")
    intEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue)
      if hasObservedOnce {
        willObserveSignal2.fulfill()
      }
      else {
        willObserveSignal1.fulfill()
        hasObservedOnce = true
      }
      return .Continue
    }

    intEmitter.emit(expectedValue)
    intEmitter.emit(expectedValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testEmitTwiceAndObserveOnce() {
    let expectedValue = 4
    var hasObservedOnce = false

    let willObserveSignal = expectationWithDescription("willObserveSignal")
    intEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue)
      XCTAssertFalse(hasObservedOnce)
      willObserveSignal.fulfill()
      hasObservedOnce = true
      return .Stop
    }

    intEmitter.emit(expectedValue)
    intEmitter.emit(expectedValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testObserveIsAsyncOnMain() {
    var shouldBe5andThen4 = 5

    let willObserve = expectationWithDescription("willObserve")
    voidEmitter.signal.observe {
      shouldBe5andThen4 = 4
      willObserve.fulfill()
      return .Continue
    }

    XCTAssertEqual(shouldBe5andThen4, 5)
    voidEmitter.emit()
    XCTAssertEqual(shouldBe5andThen4, 5)

    let willExecuteAsync = expectationWithDescription("willExecuteAsync")
    Queue.main.after(1) {
      XCTAssertEqual(shouldBe5andThen4, 4)
      willExecuteAsync.fulfill()
    }

    waitForExpectationsWithTimeout(2, handler: nil)
  }

  func testMultipleSignalsAllContinue() {
    let expectedValue1 = 9
    let expectedValue2 = 13

    var hasObservedOnce1 = false
    let willObserve1_1 = expectationWithDescription("willObserve1_1")
    let willObserve1_2 = expectationWithDescription("willObserve1_2")
    intEmitter.signal.observe { value in
      if hasObservedOnce1 {
        XCTAssertEqual(value, expectedValue2)
        willObserve1_2.fulfill()
      }
      else {
        hasObservedOnce1 = true
        XCTAssertEqual(value, expectedValue1)
        willObserve1_1.fulfill()
      }
      return .Continue
    }

    var hasObservedOnce2 = false
    let willObserve2_1 = expectationWithDescription("willObserve2_1")
    let willObserve2_2 = expectationWithDescription("willObserve2_2")
    intEmitter.signal.observe { value in
      if hasObservedOnce2 {
        XCTAssertEqual(value, expectedValue2)
        willObserve2_2.fulfill()
      }
      else {
        hasObservedOnce2 = true
        XCTAssertEqual(value, expectedValue1)
        willObserve2_1.fulfill()
      }
      return .Continue
    }

    intEmitter.emit(expectedValue1)
    intEmitter.emit(expectedValue2)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMultipleSignalsSomeContinueSomeStop() {
    let expectedValue1 = 9
    let expectedValue2 = 13

    let willObserve1_1 = expectationWithDescription("willObserve1_1")
    intEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue1)
      willObserve1_1.fulfill()
      return .Stop
    }

    var hasObservedOnce2 = false
    let willObserve2_1 = expectationWithDescription("willObserve2_1")
    let willObserve2_2 = expectationWithDescription("willObserve2_2")
    intEmitter.signal.observe { value in
      if hasObservedOnce2 {
        XCTAssertEqual(value, expectedValue2)
        willObserve2_2.fulfill()
      }
      else {
        hasObservedOnce2 = true
        XCTAssertEqual(value, expectedValue1)
        willObserve2_1.fulfill()
      }
      return .Continue
    }

    intEmitter.emit(expectedValue1)
    intEmitter.emit(expectedValue2)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testObserveAndEmitBackground() {
    let backgroundEmitter = Emitter<Int>(executionQueue: Queue.background)
    let expectedValue = 4

    let willObserveSignal = expectationWithDescription("willObserveSignal")
    backgroundEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue)
      willObserveSignal.fulfill()
      return .Continue
    }

    backgroundEmitter.emit(expectedValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMultipleSignalsSomeContinueSomeStopBackground() {
    let backgroundIntEmitter = Emitter<Int>(executionQueue: Queue.background)

    let expectedValue1 = 9
    let expectedValue2 = 13

    let willObserve1_1 = expectationWithDescription("willObserve1_1")
    backgroundIntEmitter.signal.observe { value in
      XCTAssertEqual(value, expectedValue1)
      willObserve1_1.fulfill()
      return .Stop
    }

    var hasObservedOnce2 = false
    let willObserve2_1 = expectationWithDescription("willObserve2_1")
    let willObserve2_2 = expectationWithDescription("willObserve2_2")
    backgroundIntEmitter.signal.observe { value in
      if hasObservedOnce2 {
        XCTAssertEqual(value, expectedValue2)
        willObserve2_2.fulfill()
      }
      else {
        hasObservedOnce2 = true
        XCTAssertEqual(value, expectedValue1)
        willObserve2_1.fulfill()
      }
      return .Continue
    }

    backgroundIntEmitter.emit(expectedValue1)
    backgroundIntEmitter.emit(expectedValue2)

    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
