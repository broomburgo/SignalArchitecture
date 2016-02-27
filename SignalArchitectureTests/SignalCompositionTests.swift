import XCTest
@testable import SignalArchitecture

class SignalCompositionTests: XCTestCase {
  func testMapSingle() {
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue = times2(sentValue)
    XCTAssertEqual(expectedValue, 20)

    let willObserve = expectationWithDescription("willObserve")
    intEmitter.signal.map(times2).observe { value in
      XCTAssertEqual(value, expectedValue)
      willObserve.fulfill()
      return .Continue
    }

    intEmitter.emit(sentValue)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapMultiple() {
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

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
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

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
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

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

  func testMapMultipleStop() {
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

    let times2: Int -> Int = { $0*2 }
    let sentValue = 10
    let expectedValue1 = times2(sentValue)
    let expectedValue2 = times2(times2(sentValue))
    XCTAssertEqual(expectedValue1, 20)
    XCTAssertEqual(expectedValue2, 40)

    var hasObservedOnce = false
    let willObserve1 = expectationWithDescription("willObserve1")
    intEmitter.signal.map(times2).observe { value in
      if hasObservedOnce {
        fatalError()
      }
      else {
        XCTAssertEqual(value, expectedValue1)
        willObserve1.fulfill()
        hasObservedOnce = true
      }
      return .Stop
    }

    intEmitter.emit(sentValue)
    intEmitter.emit(times2(sentValue))

    let waitForSomeTime = expectationWithDescription("waitForSomeTime")
    Queue.main.after(0.5) {
      waitForSomeTime.fulfill()
    }

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testMapAsync() {
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)

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

  func testFlatMapSingle() {

    let oldEmitter = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter = Emitter<Int>(executionQueue: Queue.main)

    let expectedValue1 = 4
    let expectedValue2 = 7
    let willFlatMap = expectationWithDescription("willFlatMap")
    let willObserve = expectationWithDescription("willObserve")

    oldEmitter.signal
      .flatMap { (value: Int) -> Signal<Int> in
        XCTAssertEqual(value, expectedValue1)
        willFlatMap.fulfill()
        return newEmitter.signal
      }
      .observe { value in
        XCTAssertEqual(value, expectedValue2)
        willObserve.fulfill()
        return .Stop
    }

    oldEmitter.signal.observe { _ in
      newEmitter.emit(expectedValue2)
      return .Continue
    }

    oldEmitter.emit(expectedValue1)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapMultiple() {

    let oldEmitter = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter = Emitter<Int>(executionQueue: Queue.main)

    let expectedValue1 = 4
    let expectedValue2 = 7
    let expectedValue3 = 13
    let willFlatMap = expectationWithDescription("willFlatMap")
    var hasObservedOnce = false
    let willObserve1 = expectationWithDescription("willObserve1")
    let willObserve2 = expectationWithDescription("willObserve2")

    oldEmitter.signal
      .flatMap { (value: Int) -> Signal<Int> in
        XCTAssertEqual(value, expectedValue1)
        willFlatMap.fulfill()
        return newEmitter.signal
      }
      .observe { value in
        if hasObservedOnce {
          XCTAssertEqual(value, expectedValue3)
          willObserve2.fulfill()
        }
        else {
          XCTAssertEqual(value, expectedValue2)
          willObserve1.fulfill()
          hasObservedOnce = true
        }
        return .Continue
    }

    oldEmitter.signal.observe { _ in
      newEmitter.emit(expectedValue2)
      newEmitter.emit(expectedValue3)
      return .Continue
    }

    oldEmitter.emit(expectedValue1)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapTwiceSingle() {
    let oldEmitter = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter1 = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter2 = Emitter<Int>(executionQueue: Queue.main)

    let expectedValue1 = 4
    let expectedValue2 = 7
    let expectedValue3 = 13
    let willFlatMap1 = expectationWithDescription("willFlatMap1")
    let willFlatMap2 = expectationWithDescription("willFlatMap2")
    let willObserve = expectationWithDescription("willObserve")

    oldEmitter.signal
      .flatMap { (value: Int) -> Signal<Int> in
        XCTAssertEqual(value, expectedValue1)
        willFlatMap1.fulfill()
        return newEmitter1.signal
      }
      .flatMap { (value: Int) -> Signal<Int> in
        XCTAssertEqual(value, expectedValue2)
        willFlatMap2.fulfill()
        return newEmitter2.signal
      }
      .observe { value in
        XCTAssertEqual(value, expectedValue3)
        willObserve.fulfill()
        return .Stop
    }

    oldEmitter.emit(expectedValue1)

    Queue.main.after(0.333) {
      newEmitter1.emit(expectedValue2)
    }

    Queue.main.after(0.666) {
      newEmitter2.emit(expectedValue3)
    }

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapAsync() {
    let intEmitter = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter = Emitter<Int>(executionQueue: Queue.main)

    var shouldbe4 = 4

    let willFlatMap = expectationWithDescription("willFlatMap")
    intEmitter.signal.flatMap { (value: Int) -> Signal<Int> in
      shouldbe4 = 5
      willFlatMap.fulfill()
      return newEmitter.signal
    }

    XCTAssertEqual(shouldbe4, 4)
    intEmitter.emit(7)
    XCTAssertEqual(shouldbe4, 4)
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFlatMapMultipleStop() {

    let oldEmitter = Emitter<Int>(executionQueue: Queue.main)
    let newEmitter = Emitter<Int>(executionQueue: Queue.main)

    let expectedValue1 = 4
    let expectedValue2 = 7
    let expectedValue3 = 13
    let willFlatMap = expectationWithDescription("willFlatMap")
    var hasObservedOnce = false
    let willObserve1 = expectationWithDescription("willObserve1")

    oldEmitter.signal
      .flatMap { (value: Int) -> Signal<Int> in
        XCTAssertEqual(value, expectedValue1)
        willFlatMap.fulfill()
        return newEmitter.signal
      }
      .observe { value in
        if hasObservedOnce {
          fatalError()
        }
        else {
          XCTAssertEqual(value, expectedValue2)
          willObserve1.fulfill()
          hasObservedOnce = true
        }
        return .Stop
    }

    oldEmitter.signal.observe { _ in
      newEmitter.emit(expectedValue2)
      newEmitter.emit(expectedValue3)
      newEmitter.emit(expectedValue2)
      newEmitter.emit(expectedValue3)
      return .Continue
    }

    oldEmitter.emit(expectedValue1)

    let waitForSomeTime = expectationWithDescription("waitForSomeTime")
    Queue.main.after(0.5) {
      waitForSomeTime.fulfill()
    }

    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
