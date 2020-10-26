// MARK: Subject to change prior to 1.0.0 release
// MARK: -

import Foundation

/// Capable of being encoded as `ZeroData`.
public protocol ZeroDataRepresentable {
    /// Converts `self` to `ZeroData`, returning `nil` if the conversion is not possible.
    var zeroData: ZeroData { get }
}

// MARK: Default Conformances

extension String: ZeroDataRepresentable {
    public var zeroData: ZeroData { .string(self) }
}

extension FixedWidthInteger {
    public var zeroData: ZeroData {
        guard let valid = Int(exactly: self) else { return .int(nil) }
        return .int(Int(valid))
    }
}

extension Int8: ZeroDataRepresentable {}
extension Int16: ZeroDataRepresentable {}
extension Int32: ZeroDataRepresentable {}
extension Int64: ZeroDataRepresentable {}
extension Int: ZeroDataRepresentable {}
extension UInt8: ZeroDataRepresentable {}
extension UInt16: ZeroDataRepresentable {}
extension UInt32: ZeroDataRepresentable {}
extension UInt64: ZeroDataRepresentable {}
extension UInt: ZeroDataRepresentable {}

extension BinaryFloatingPoint {
    public var zeroData: ZeroData {
        guard let valid = Double(exactly: self) else { return .double(nil) }
        return .double(Double(valid))
    }
}

extension Float: ZeroDataRepresentable {}
extension Double: ZeroDataRepresentable {}
extension Float80: ZeroDataRepresentable {}

extension Bool: ZeroDataRepresentable {
    public var zeroData: ZeroData { .bool(self) }
}

extension UUID: ZeroDataRepresentable {
    public var zeroData: ZeroData { .string(ZeroConfiguration.stringFormatter(description)) }
}

extension Date: ZeroDataRepresentable {
    public var zeroData: ZeroData { .double(timeIntervalSince1970) }
}

extension Array where Element == ZeroData {
    public var zeroData: ZeroData { .array(self.map { $0 }) }
}

extension Dictionary where Key == String, Value == ZeroData {
    public var zeroData: ZeroData { .dictionary(self.mapValues { $0 }) }
}

extension Set where Element: ZeroDataRepresentable {
    public var zeroData: ZeroData { .array(self.map { $0.zeroData }) }
}

extension Array where Element: ZeroDataRepresentable {
    public var zeroData: ZeroData { .array(self.map { $0.zeroData }) }
}

extension Dictionary where Key == String, Value: ZeroDataRepresentable {
    public var zeroData: ZeroData { .dictionary(self.mapValues { $0.zeroData }) }
}
