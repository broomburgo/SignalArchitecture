import Foundation

struct Queue {
  private let dispatchQueue: dispatch_queue_t
  init(dispatchQueue: dispatch_queue_t) {
    self.dispatchQueue = dispatchQueue
  }

  static var main: Queue {
    return Queue(dispatchQueue: dispatch_get_main_queue())
  }

  static var background: Queue {
    return Queue(dispatchQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
  }

  func async(callback: () -> ()) {
    dispatch_async(dispatchQueue, callback)
  }

  func sync(callback: () -> ()) {
    dispatch_sync(dispatchQueue, callback)
  }
}