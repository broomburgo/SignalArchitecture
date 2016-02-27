import Foundation

extension Signal {
  func map<OtherWrapped>(transform: Wrapped -> OtherWrapped) -> Signal<OtherWrapped> {
    let newEmitter = Emitter<OtherWrapped>(executionQueue: executionQueue)
    observe { value in
      newEmitter.emit(transform(value))
      return .Continue
    }
    return newEmitter.signal
  }

  func flatMap<OtherWrapped>(transform: Wrapped -> Signal<OtherWrapped>) -> Signal<OtherWrapped> {
    let newEmitter = Emitter<OtherWrapped>(executionQueue: executionQueue)
    observe { value in
      let otherEmitter = transform(value)
      otherEmitter.observe { otherValue in
        newEmitter.emit(otherValue)
        return .Continue
      }
      return .Continue
    }
    return newEmitter.signal
  }
}