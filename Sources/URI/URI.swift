
public struct URI {
    public let scheme: String
    public let host: String
    public let userInfo: String?
    public let port: Int?
    public let path: String
    public let query: String
    public let fragment: String
    let storage: String = ""

    public init(_ string: String) throws {
        var parser = Parser(string)
        try parser.parse()
        scheme = parser.scheme
        host = parser.host
        port = parser.port
        userInfo = parser.userInfo
        path = parser.path
        query = parser.query
        fragment = parser.fragment
    }
}

extension URI: CustomStringConvertible {
    public var description: String {
        return "<URI: Scheme='\(scheme)'>"
    }
}

extension UInt8 {

    func isPathDelimiter() -> Bool {
        switch self {
        case UInt8(ascii: "?"),
             UInt8(ascii: "#"):
            return true
        default:
            return false
        }
    }

    func isReserved() -> Bool {
        switch self {
        case UInt8(ascii: ":"),
             UInt8(ascii: "/"),
             UInt8(ascii: "?"),
             UInt8(ascii: "#"),
             UInt8(ascii: "["),
             UInt8(ascii: "]"),
             UInt8(ascii: "@"):
            return true
        default:
            return false
        }
    }

    func isUnreserved() -> Bool {
        switch self {
        case UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "A")...UInt8(ascii: "Z"),
             UInt8(ascii: "."),
             UInt8(ascii: "_"),
             UInt8(ascii: "~"),
             UInt8(ascii: "-"):
            return true
        default:
            return false
        }
    }

    func isQuestionMark() -> Bool {
        return self == UInt8(ascii: "?")
    }

    func isPound() -> Bool {
        return self == UInt8(ascii: "#")
    }

    func isAtSign() -> Bool {
        return self == UInt8(ascii: "@")
    }

    func isLSquareBracket() -> Bool {
        return self == UInt8(ascii: "[")
    }

    func isRSquareBracket() -> Bool {
        return self == UInt8(ascii: "]")
    }

    func isColon() -> Bool {
        return self == UInt8(ascii: ":")
    }

    func isHyphen() -> Bool {
        return self == UInt8(ascii: "-")
    }

    func isPeriod() -> Bool {
        return self == UInt8(ascii: ".")
    }

    func isUnderscore() -> Bool {
        return self == UInt8(ascii: "_")
    }

    func isTilde() -> Bool {
        return self == UInt8(ascii: "~")
    }

    func isForwardSlash() -> Bool {
        return self == UInt8(ascii: "/")
    }

    func isDigit() -> Bool {
        switch self {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return true
        default:
            return false
        }
    }

    func isAlpha() -> Bool {
        switch self {
        case UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "A")...UInt8(ascii: "Z"):
            return true
        default:
            return false
        }
    }

    // Represent (Alpha / digit / + / - / .)
    func isValidSchemePart() -> Bool {
        switch self {
        case UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "A")...UInt8(ascii: "Z"),
             UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "+"),
             UInt8(ascii: "-"),
             UInt8(ascii: "."):
            return true
        default:
            return false
        }
    }
}

public enum URIError: Swift.Error {
    case parsingError(String)
}

struct Parser {
    let data: String
    var utf8: String.UTF8View { return data.utf8 }
    var index: String.UTF8View.Index
    var lookahead: UInt8? = nil
    var nextIndex: String.UTF8View.Index? = nil

    var scheme = ""
    var host = ""
    var port: Int?
    var userInfo: String?
    var path = ""
    var query = ""
    var fragment = ""

    init(_ string: String) {
        self.data = string
        self.index = self.data.utf8.startIndex
    }

    // URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    mutating func parse() throws {
        try parseScheme()
        // If we reached end of string or next char is not a colon, the URI is complete.
        if !(look()?.isColon() ?? false) {
            throw URIError.parsingError("Incomplete URI expected colon.")
        }
        consume()
        try parseHierPart()
        if let c = look(), c.isQuestionMark() {
            consume()
            try parseQuery()
        }

        if let c = look(), c.isPound() {
            consume()
            try parseFragment()
        }
    }

    mutating func parseQuery() throws {
        let startIndex = index
        while let c = look(), !c.isPound() {
            consume()
        }
        query = String(utf8[startIndex..<index])!
    }

    mutating func parseFragment() throws {
        fragment = String(utf8[index..<utf8.endIndex])!
    }

    // scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    // delimiter is colon.
    mutating func parseScheme() throws {
        let startIndex = index
        guard let c = look(), c.isAlpha() else { throw URIError.parsingError("Scheme should start with an alphabet.") }
        while let c = look(), !c.isColon() {
            if c.isValidSchemePart() {
                consume()
            } else {
                throw URIError.parsingError("Invalid char \(c) in scheme.")
            }
        }
        scheme = String(utf8[startIndex..<index])!
    }

    // hier-part   = "//" authority path-abempty / path-absolute / path-rootless / path-empty
    mutating func parseHierPart() throws {
        if let c = look(), c.isForwardSlash() {
            consume()
            if let c = look(), c.isForwardSlash() {
                consume()
                try parseAuthority()
                try parsePath()
            } else {
                throw URIError.parsingError("Expected /")
            }
        } else {
            throw URIError.parsingError("URI not yet supported.")
        }
    }

    // authority = [ userinfo "@" ] host [ ":" port ]
    mutating func parseAuthority() throws {
        try parseHost()
        if let c = look(), c.isColon() {
            consume()
            try parsePort()
        }
    }

    // host = IP-literal / IPv4address / reg-name
    mutating func parseHost() throws {
        // IP-literal = "[" ( IPv6address / IPvFuture  ) "]"
        if let c = look(), c.isLSquareBracket() {
            consume()
            let startIndex = index
            while let c = look(), !c.isRSquareBracket() {
                // FIXME: This doesn't validate IPv6/IPvFuture yet.
                consume()
            }
            host = String(utf8[startIndex..<index])!
            if !(look()?.isRSquareBracket() ?? false) {
                throw URIError.parsingError("Incomplete URI expected ].")
            }
            consume() // consume ]
            return
        }

        outer: while true {
            let startIndex = index
            while let c = look() {
                if c.isAtSign() {
                    userInfo = String(utf8[startIndex..<index])!
                    consume()
                    break
                }
                // IPv4address / reg-name
                // FIXME: Doesn't validates, parses blindly till first reserved char.
                if c.isReserved() {
                    host = String(utf8[startIndex..<index])!
                    break outer
                }
                consume()
            }
            if look() == nil { break outer }
        }
    }

    mutating func parsePort() throws {
        let startIndex = index
        while let c = look(), c.isDigit() {
            consume()
        }
        port = Int(String(utf8[startIndex..<index])!)!
    }

    mutating func parsePath() throws {
        let startIndex = index
        while let c = look(), !c.isPathDelimiter() {
            consume()
        }
        path = String(utf8[startIndex..<index])!
    }

    mutating func look() -> UInt8? {
        if let c = lookahead {
            return c
        }

        if index == utf8.endIndex {
            return nil
        }

        lookahead = utf8[index]
        nextIndex = utf8.index(after: index)
        return lookahead
    }

    @discardableResult
    mutating func consume() -> UInt8? {
        guard let c = look() else { return nil }
        lookahead = nil
        index = nextIndex!
        return c
    }
}
