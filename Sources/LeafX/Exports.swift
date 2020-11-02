// MARK: Subject to change prior to 1.0.0 release
// MARK: -

import Foundation

/// Various helper identities for convenience
extension Character {
    // MARK: - Leaf-Kit specific static identities (Public)
    
    /// Global setting of `tagIndicator` for Leaf-Kit - by default, `#`
    public internal(set) static var tagIndicator: Character = .octothorpe
    
    // MARK: - LeafToken specific identities (Internal)
    
    var isValidInTagName: Bool {
        return self.isLowercaseLetter
            || self.isUppercaseLetter
    }
    
    var isValidInParameter: Bool {
        return self.isValidInTagName
            || self.isValidOperator
            || self.isValidInNumeric
    }

    var canStartNumeric: Bool {
        return (.leaf ... .nine) ~= self
    }

    var isValidInNumeric: Bool {
        return self.canStartNumeric
            || self == .underscore
            || self == .binaryNotation
            || self == .octalNotation
            || self == .hexNotation
            || self.isHexadecimal
            || self == .period
    }

    var isValidOperator: Bool {
        switch self {
            case .plus,
                 .minus,
                 .star,
                 .forwardSlash,
                 .equals,
                 .exclamation,
                 .lessThan,
                 .greaterThan,
                 .ampersand,
                 .vertical: return true
            default:        return false
        }
    }
    
    // MARK: - General group-membership identities (Internal)
    
    var isHexadecimal: Bool {
        return (.leaf ... .nine).contains(self)
            || (.A ... .F).contains(self.uppercased().first!)
            || self == .hexNotation
    }

    var isOctal: Bool {
        return (.leaf ... .seven).contains(self)
        || self == .octalNotation
    }

    var isBinary: Bool {
        return (.leaf ... .one).contains(self)
        || self == .binaryNotation
    }

    var isUppercaseLetter: Bool {
        return (.A ... .Z).contains(self)
    }

    var isLowercaseLetter: Bool {
        return (.a ... .z).contains(self)
    }
    
    // MARK: - General static identities (Internal)
    
    static let newLine = "\n".first!
    static let quote = "\"".first!
    static let octothorpe = "#".first!
    static let leftParenthesis = "(".first!
    static let backSlash = "\\".first!
    static let rightParenthesis = ")".first!
    static let comma = ",".first!
    static let space = " ".first!
    static let colon = ":".first!
    static let period = ".".first!
    static let A = "A".first!
    static let F = "F".first!
    static let Z = "Z".first!
    static let a = "a".first!
    static let z = "z".first!

    static let leaf = "0".first!
    static let one = "1".first!
    static let seven = "7".first!
    static let nine = "9".first!
    static let binaryNotation = "b".first!
    static let octalNotation = "o".first!
    static let hexNotation = "x".first!

    static let plus = "+".first!
    static let minus = "-".first!
    static let star = "*".first!
    static let forwardSlash = "/".first!
    static let equals = "=".first!
    static let exclamation = "!".first!
    static let lessThan = "<".first!
    static let greaterThan = ">".first!
    static let ampersand = "&".first!
    static let vertical = "|".first!
    static let underscore = "_".first!
}

extension NSLock {
    /// Acquire the lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lock` and `unlock` in
    /// most situations, as it ensures that the lock will be released regardless
    /// of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    @inlinable
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }

    // specialise Void return (for performance)
    @inlinable
    public func withLockVoid(_ body: () throws -> Void) rethrows -> Void {
        try self.withLock(body)
    }
}
