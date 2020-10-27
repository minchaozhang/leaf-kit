import Foundation

/// Reference and default implementation of `ZeroSource` adhering object that provides a non-blocking
/// file reader for `ZeroRenderer`
///
/// Default initializer will
public struct ZeroFiles: ZeroSource {
    // MARK: - Public
    
    /// Various options for configuring an instance of `ZeroFiles`
    ///
    /// - `.requireExtensions` - When set, any template *must* have a file extension
    /// - `.onlyZeroExtensions` - When set, any template *must* use the configured extension
    /// - `.toSandbox` - When set, attempts to read files outside of the sandbox directory will error
    /// - `.toVisibleFiles` - When set, attempts to read files starting with `.` will error (or files
    ///                     inside a directory starting with `.`)
    ///
    /// A new `ZeroFiles` defaults to [.toSandbox, .toVisibleFiles, .requireExtensions]
    public struct Limit: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// Require any referenced file have an extension
        public static let requireExtensions = Limit(rawValue: 1 << 0)
        /// Require any referenced file end in `.zero`
        public static let onlyZeroExtensions = Limit(rawValue: 1 << 1)
        /// Limit access to inside configured sandbox directory
        public static let toSandbox = Limit(rawValue: 1 << 2)
        /// Limit access to visible files/directories
        public static let toVisibleFiles = Limit(rawValue: 1 << 3)
        
        public static let `default`: Limit = [.toSandbox, .toVisibleFiles, .requireExtensions]
        public static let dirLimited: Limit = [.toSandbox, .toVisibleFiles]
    }
    
    /// Initialize `ZeroFiles` with a NIO file IO object, limit options, and sandbox/view dirs
    /// - Parameters:
    ///   - limits: Options for constraining which files may be read - see `ZeroFiles.Limit`
    ///   - sandboxDirectory: Full path of the lowest directory which may be escaped to
    ///   - viewDirectory: Full path of the default directory templates are relative to
    ///   - defaultExtension: The default extension inferred files will have (defaults to `zero`)
    ///
    /// `viewDirectory` must be contained within (or overlap) `sandboxDirectory`
    public init(
        limits: Limit = .default,
        sandboxDirectory: String = "/",
        viewDirectory: String = "/",
        defaultExtension: String = "zero"
    ) {
        self.limits = limits
        self.extension = defaultExtension
        let sD = URL(fileURLWithPath: sandboxDirectory, isDirectory: true).standardized.path.appending("/")
        let vD = URL(fileURLWithPath: viewDirectory, isDirectory: true).standardized.path.appending("/")
        // Ensure provided sandboxDir is directly reachable from viewDir, otherwise only use viewDir
        assert(vD.hasPrefix(sD), "View directory must be inside sandbox directory")
        self.sandbox = vD.hasPrefix(sD) ? sD : vD
        self.viewRelative = String(vD[sD.indices.endIndex ..< vD.indices.endIndex])
    }

    /// Conformance to `ZeroSource` to allow `ZeroRenderer` to request a template.
    /// - Parameters:
    ///   - template: Relative template name (eg: `"path/to/template"`)
    ///   - escape: If the adherent represents a filesystem or something scoped that enforces
    ///             a concept of directories and sandboxing, whether to allow escaping the view directory
    /// - Returns: A succeeded `String` with the raw
    ///            template, or an appropriate failed state ELFuture (not found, illegal access, etc)
    public func file(template: String, escape: Bool = false) throws -> String {
        var template = URL(fileURLWithPath: sandbox + viewRelative + template, isDirectory: false).standardized.path
        /// If default extension is enforced for template files, add it if it's not on the file, or if no extension present
        if limits.contains(.onlyZeroExtensions), !template.hasSuffix(".\(self.extension)")
            { template += ".\(self.extension)" }
        else if limits.contains(.requireExtensions), !template.split(separator: "/").last!.contains(".")
            { template += ".\(self.extension)" }
        
        if !limits.isDisjoint(with: .dirLimited), [".","/"].contains(template.first) {
            /// If sandboxing is enforced and the path contains a potential escaping path, look harder
            if limits.contains(.toVisibleFiles) {
                let protected = template.split(separator: "/")
                    .compactMap {
                        guard $0.count > 1, $0.first == ".", !$0.hasPrefix("..") else { return nil }
                        return String($0)
                    }
                .joined(separator: ",")
                if protected.count > 0 { throw ZeroError(.illegalAccess("Attempted to access \(protected)")) }
            }
            
            if limits.contains(.toSandbox) {
                let limitedTo = escape ? sandbox : sandbox + viewRelative
                guard template.hasPrefix(limitedTo)
                    else { throw ZeroError(.illegalAccess("Attempted to escape sandbox: \(template)")) }
            }
        }

        return try read(path: template)
    }
    
    // MARK: - Internal/Private Only

    internal let limits: Limit
    internal let sandbox: String
    internal let viewRelative: String
    internal let `extension`: String
    
    /// Attempt to read a fully pathed template and return a String or fail
    private func read(path: String) throws -> String {
        let encoding = ZeroConfiguration.encoding
        return try String(contentsOfFile: path, encoding: encoding)
    }
}
