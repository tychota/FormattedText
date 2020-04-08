import Foundation

/**
 Data structure to represent LIFO (last in first out)
 
 - parameter element: an Element of type T is pushed into the stack then peek ou pop out of the stack.
 
 */
struct Stack<T> {
    typealias Element = T
    
    private var items: [Element] = []
    
    // MARK: - Main Api
    
    /// Add a new element on top of the stack
    mutating func push(_ element: Element) {
        items.append(element)
    }
    
    /// Remove the element (null, if Stack is empty) and get it back
    mutating func pop() -> Element? {
        return items.popLast()
    }
    
    /// Look at the top element without mutating the stack
    func peek() -> Element? {
        return items.last
    }
    
    // MARK: - Helper
    
    /// Return true if the stack has no element, else true
    func isEmpty() -> Bool {
        return items.isEmpty
    }
    
    /// Return the number of items in the stack
    var count: Int {
        return items.count
    }
    
    func toArray() -> [Element] {
        return items.reversed()
    }
}

extension Stack where T: Equatable {
    func contains(_ element: Element) -> Bool {
        return items.contains(element)
    }
}
