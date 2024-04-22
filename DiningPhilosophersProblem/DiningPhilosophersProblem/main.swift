//
//  main.swift
//  DiningPhilosophersProblem
//
//  Created by Arina Zabrodina on 13/04/2024.
//

import Foundation
import Combine

var philosophers: [Philosopher] = []

final class Philosopher {
  
  private var cancallables: [AnyCancellable] = []
  
  let didFinishDish = PassthroughSubject<Void, Never>()
  var leftNeighbor: Philosopher! {
    didSet {
      guard let leftNeighbor else { return }
      
      leftNeighbor.didFinishDish.sink {
        self.testIfCanEat()
      }.store(in: &cancallables)
    }
  }
  var rightNeighbor: Philosopher! {
    didSet {
      guard let rightNeighbor else { return }
      
      rightNeighbor.didFinishDish.sink {
        self.testIfCanEat()
      }.store(in: &cancallables)
    }
  }
  var state: State = .thinking
  let bothForkAvailable = DispatchSemaphore(value: 0)
  let position: Int
  
  init(position: Int) {
    self.position = position
  }
  
  enum State {
    case hungry
    case thinking
    case eating
  }
  
  func generateDelay() -> TimeInterval {
    let minDelay: TimeInterval = 0.5
    let maxDelay: TimeInterval = 1.0
    
    let delay: TimeInterval = .random(in: minDelay...maxDelay)
    return delay
  }
  
  func think() {
    state = .thinking
    let delay = generateDelay()
    print("\(position) is thinking for \(delay)")
    Thread.sleep(forTimeInterval: delay)
  }
  
  func takeForks() {
    state = .hungry
    print("\t\(position) is hungry")
    testIfCanEat()
    bothForkAvailable.wait()
  }
  
  private func testIfCanEat() {
    if state == .hungry,
       leftNeighbor.state != .eating,
       rightNeighbor.state != .eating {
      state = .eating
      bothForkAvailable.signal()
    }
  }
  
  func eat() {
    self.state = .eating
    
    let delay = generateDelay() + 0.3
    print("\t\t\(position) is eating for \(delay)")
    Thread.sleep(forTimeInterval: delay)
    
  }
  
  func putForks() {
    state = .thinking
    didFinishDish.send()
  }
  
  func start() {
    while(true) {
      think()
      takeForks()
      eat()
      putForks()
    }
  }
  
}

func main() {
  let n = 5
  for i in 1...n {
    let newPhilosopher = Philosopher(position: i)
    if let prevPhilosopher = philosophers.last {
      prevPhilosopher.rightNeighbor = newPhilosopher
      newPhilosopher.leftNeighbor = prevPhilosopher
    }
    philosophers.append(newPhilosopher)
  }
  philosophers.first?.leftNeighbor = philosophers.last
  philosophers.last?.rightNeighbor = philosophers.first
  
  for philosopher in philosophers {
    Thread {
      philosopher.start()
    }.start()
  }
  while(true) { }
}

main()
