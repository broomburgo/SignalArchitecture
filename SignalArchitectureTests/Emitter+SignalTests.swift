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
}
