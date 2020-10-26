// MARK: Subject to change prior to 1.0.0 release
// MARK: -

public protocol ZeroTag {
    func render(_ ctx: ZeroContext) throws -> ZeroData
}

public var defaultTags: [String: ZeroTag] = [
    "lowercased": Lowercased()
]

struct Lowercased: ZeroTag {
    func render(_ ctx: ZeroContext) throws -> ZeroData {
        guard let str = ctx.parameters.first?.string else {
            throw "unable to lowercase unexpected data"
        }
        return .init(.string(str.lowercased()))
    }
}
