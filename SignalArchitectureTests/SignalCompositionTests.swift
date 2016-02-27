import XCTest
@testable import SignalArchitecture

class SignalCompositionTests: XCTestCase {
  var intEmitter = Emitter<Int>(executionQueue: Queue.main)

  func testMapSingle() {
    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue = times2(sentValue)
    XCTAssertEqual(expectedValue, 20)

    let willObserve = expectationWithDescription("willObserve")
    intEmitter.signal.map(times2).observe { value in
      XCTAssertEqual(value, expectedValue)
      willObserve.fulfill()
      return .Stop
    }

    intEmitter.emit(sentValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapMultiple() {
    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue1 = times2(sentValue)
    let expectedValue2 = times2(times2(sentValue))
    XCTAssertEqual(expectedValue1, 20)
    XCTAssertEqual(expectedValue2, 40)

    var hasObservedOnce = false
    let willObserve1 = expectationWithDescription("willObserve1")
    let willObserve2 = expectationWithDescription("willObserve2")
    intEmitter.signal.map(times2).observe { value in
      if hasObservedOnce {
        XCTAssertEqual(value, expectedValue2)
        willObserve2.fulfill()
      }
      else {
        XCTAssertEqual(value, expectedValue1)
        willObserve1.fulfill()
        hasObservedOnce = true
      }
      return .Continue
    }

    intEmitter.emit(sentValue)
    intEmitter.emit(times2(sentValue))

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapTwiceSingle() {
    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue = times2(times2(sentValue))
    XCTAssertEqual(expectedValue, 40)

    let willObserve = expectationWithDescription("willObserve")
    intEmitter.signal.map(times2).map(times2).observe { value in
      XCTAssertEqual(value, expectedValue)
      willObserve.fulfill()
      return .Stop
    }

    intEmitter.emit(sentValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapTwiceMultiple() {
    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue1 = times2(times2(sentValue))
    let expectedValue2 = times2(times2(times2(sentValue)))
    XCTAssertEqual(expectedValue1, 40)
    XCTAssertEqual(expectedValue2, 80)

    var hasObservedOnce = false
    let willObserve1 = expectationWithDescription("willObserve1")
    let willObserve2 = expectationWithDescription("willObserve2")
    intEmitter.signal.map(times2).map(times2).observe { value in
      if hasObservedOnce {
        XCTAssertEqual(value, expectedValue2)
        willObserve2.fulfill()
      }
      else {
        XCTAssertEqual(value, expectedValue1)
        willObserve1.fulfill()
        hasObservedOnce = true
      }
      return .Continue
    }

    intEmitter.emit(sentValue)
    intEmitter.emit(times2(sentValue))

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapAsync() {
    var shouldbe4 = 4

    let willMap = expectationWithDescription("willMap")
    intEmitter.signal.map { (value: Int) -> Int in
      shouldbe4 = 5
      willMap.fulfill()
      return value
    }

    XCTAssertEqual(shouldbe4, 4)

    intEmitter.emit(7)

    XCTAssertEqual(shouldbe4, 4)

    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
