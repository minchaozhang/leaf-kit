// MARK: Subject to change prior to 1.0.0 release
// MARK: -


/// `ZeroAST` represents a "compiled," grammatically valid Zero template (which may or may not be fully resolvable or erroring)
public struct ZeroAST: Hashable {
    // MARK: - Public
    
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
    public static func == (lhs: ZeroAST, rhs: ZeroAST) -> Bool { lhs.name == rhs.name }

    // MARK: - Internal/Private Only
    let name: String

    init(name: String, ast: [Syntax]) {
        self.name = name
        self.ast = ast
        self.rawAST = nil
        self.flat = false

        updateRefs([:])
    }
    
    init(from: ZeroAST, referencing externals: [String: ZeroAST]) {
        self.name = from.name
        self.ast = from.ast
        self.rawAST = from.rawAST
        self.externalRefs = from.externalRefs
        self.unresolvedRefs = from.unresolvedRefs
        self.flat = from.flat

        updateRefs(externals)
    }

    internal private(set) var ast: [Syntax]
    internal private(set) var externalRefs = Set<String>()
    internal private(set) var unresolvedRefs = Set<String>()
    internal private(set) var flat: Bool
    
    // MARK: - Private Only
    
    private var rawAST: [Syntax]?

    mutating private func updateRefs(_ externals: [String: ZeroAST]) {
        var firstRun = false
        if rawAST == nil, flat == false { rawAST = ast; firstRun = true }
        unresolvedRefs.removeAll()
        var pos = ast.startIndex

        // inline provided externals
        while pos < ast.endIndex {
            // get desired externals for this Syntax - if none, continue
            let wantedExts = ast[pos].externals()
            if wantedExts.isEmpty {
                pos = ast.index(after: pos)
                continue
            }
            // see if we can provide any of them - if not, continue
            let providedExts = externals.filter { wantedExts.contains($0.key) }
            if providedExts.isEmpty {
                unresolvedRefs.formUnion(wantedExts)
                pos = ast.index(after: pos)
                continue
            }
            
            // replace the original Syntax with the results of inlining, potentially 1...n
            let replacementSyntax = ast[pos].inlineRefs(providedExts, [:])
            ast.replaceSubrange(pos...pos, with: replacementSyntax)
            // any returned new inlined syntaxes can't be further resolved at this point
            // but we need to add their unresolvable references to the global set
            var offset = replacementSyntax.startIndex
            while offset < replacementSyntax.endIndex {
                unresolvedRefs.formUnion(ast[pos].externals())
                offset = replacementSyntax.index(after: offset)
                pos = ast.index(after: pos)
            }
        }

        // compress raws
        pos = ast.startIndex
        while pos < ast.index(before: ast.endIndex) {
            if case .raw(let syntax) = ast[pos] {
                if case .raw(let add) = ast[ast.index(after: pos)] {
                    ast[pos] = .raw(syntax + add)
                    ast.remove(at: ast.index(after: pos) )
                } else { pos = ast.index(after: pos) }
            } else { pos = ast.index(after: pos) }
        }

        flat = unresolvedRefs.isEmpty ? true : false
        if firstRun && flat { rawAST = nil }
    }
}
