import Foundation

enum SignalContinuation {
  case Stop
  case Continue
}

struct Emitter<Wrapped> {
  let signal: Signal<Wrapped>

  init(executionQueue: Queue) {
    self.signal = Signal<Wrapped>(executionQueue: executionQueue)
  }

  func emit(value: Wrapped) {
    signal.send(value: value)
  }
}

class Signal<Wrapped> {
  typealias ObserverCallback = Wrapped -> SignalContinuation
  func observe(callback: ObserverCallback) -> Signal {
    addCallbackAsync(callback)
    return self
  }

  private let executionQueue: Queue
  private init(executionQueue: Queue) {
    self.executionQueue = executionQueue
  }

  private var observers: [ObserverCallback] = []
  private var values: [Wrapped] = []
  private var isCheckingValues = false
}

/// private methods
extension Signal {
  private func addCallbackAsync(callback: ObserverCallback) {
    Queue.main.async { [weak self] in
      print("adding callback: \(callback)")
      self?.observers.append(callback)
    }
  }

  private func addValueAsync(value: Wrapped) {
    Queue.main.async { [weak self] in
      print("adding value: \(value)")
      self?.values.append(value)
    }
  }

  private func checkValues() {
    Queue.main.async { [weak self] in
      print("is checking values: \(self?.values)")
      guard let this = self, let firstValue = this.values.first
        where this.isCheckingValues == false else { return }
      this.isCheckingValues = true
      this.values.removeFirst()
      print("will execute callbacks on first value: \(firstValue)")
      this.executeCallbacksAsync(value: firstValue) { [weak self] in
        guard let this = self else { return }
        this.isCheckingValues = false
        this.checkValues()
      }
    }
  }

  private func executeCallbacksAsync(value value: Wrapped, completion: () -> ()) {
    Queue.main.async { [weak self] in

      guard let callbacksToExecute = self?.observers
        where callbacksToExecute.count > 0  else { return }
      print("callback to execute: \(callbacksToExecute)")
      self?.observers.removeAll()

      self?.executionQueue.async {

        let remainingCallbacks = Signal.callAndReturnIfNeeded(
          callbacks: callbacksToExecute,
          value: value)

        Queue.main.async { [weak self] in

          print("will append remaining callbacks: \(remainingCallbacks)")
          self?.observers.appendContentsOf(remainingCallbacks)
          completion()
        }
      }
    }
  }

  private static func callAndReturnIfNeeded(
    callbacks callbacks: [ObserverCallback],
    value: Wrapped) -> [ObserverCallback]
  {
    var newCallbacks: [ObserverCallback] = []
    for callback in callbacks {
      print("will execute callback \(callback) with value \(value)")
      switch callback(value) {
      case .Stop:
        break
      case .Continue:
        newCallbacks.append(callback)
      }
    }
    return newCallbacks
  }
}

/// private interface for sending values: visible only to Emitter
extension Signal {
  private func send(value value: Wrapped) {
    addValueAsync(value)
    checkValues()
  }
}
