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
}