
public struct URI {
    public let scheme: String
    public let host = ""
    public let user = ""
    public let port = 0
    public let path = ""
    public let query = ""
    public let fragment = ""
    let storage: String = ""

    public init(_ string: String) throws {
        var parser = Parser(string)
        try parser.parse()
        scheme = parser.scheme
    }
}

extension URI: CustomStringConvertible {
    public var description: String {
        return "<URI: Scheme='\(scheme)'>"
    }
}

extension UInt8 {

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

    // scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    // Represent *(Alpha / digit / ...)
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

    init(_ string: String) {
        self.data = string
        self.index = self.data.utf8.startIndex
    }

    mutating func parse() throws {
        try parseScheme()
    }

    mutating func parseScheme() throws {
        let startIndex = index
        guard let c = look(), c.isAlpha() else { throw URIError.parsingError("Scheme should start with an alphabet.") }
        while let c = look(), !c.isColon() {
            if c.isValidSchemePart() {
                let _ = consume()
            } else {
                throw URIError.parsingError("Invalid char \(c) in scheme.")
            }
        }
        // If we reached end of string, the scheme and URI is complete.
        if look() == nil {
            throw URIError.parsingError("Incomplete scheme.")
        }
        scheme = String(utf8[startIndex..<index])!
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

    mutating func consume() -> UInt8? {
        guard let c = look() else { return nil }
        lookahead = nil
        index = nextIndex!
        return c
    }
}
