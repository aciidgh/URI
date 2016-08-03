import XCTest
@testable import URI

class URITests: XCTestCase {

    func testBasic() {
        URITester("http") { result in
            result.checkError("Incomplete URI expected colon.")
        }

        URITester("http://www.ietf.org/rfc/rfc2396.txt") { result in
            result.checkScheme("http")
            result.checkHost("www.ietf.org")
            result.checkPort(nil)
        }

        URITester("http://www.ietf.org:91/rfc/rfc2396.txt") { result in
            result.checkScheme("http")
            result.checkHost("www.ietf.org")
            result.checkPort(91)
        }

        URITester("ftp://ftp.is.co.za/rfc/rfc1808.txt") { result in
            result.checkScheme("ftp")
            result.checkHost("ftp.is.co.za")
            result.checkPort(nil)
        }

        URITester("ldap://[2001:db8::7]/c=GB?objectClass?one") { result in
            result.checkScheme("ldap")
            result.checkHost("2001:db8::7")
            result.checkPort(nil)
        }

   //     URITester("mailto:John.Doe@example.com") { result in
   //         result.checkScheme("mailto")
   //     }

 //       URITester("news:comp.infosystems.www.servers.unix") { result in
 //           result.checkScheme("news")
 //       }

  //      URITester("tel:+1-816-555-1212") { result in
  //          result.checkScheme("tel")
  //      }

        URITester("telnet://192.0.2.16:8093/") { result in
            result.checkScheme("telnet")
            result.checkHost("192.0.2.16")
            result.checkPort(8093)
        }

  //      URITester("urn:oasis:names:specification:docbook:dtd:xml:4.1.2") { result in
  //          result.checkScheme("urn")
  //      }
    }

    static var allTests : [(String, (URITests) -> () throws -> Void)] {
        return [
            ("testBasic", testBasic),
        ]
    }
}

enum Result {
    case uri(URI)
    case error(String)
}

func URITester(_ string: String, file: StaticString = #file, line: UInt = #line, _ body: (URITesterResult) -> Void) {
    let result: Result
    do {
        result = .uri(try URI(string))
    } catch URIError.parsingError(let desc) {
        result = .error(desc)
    } catch {
        XCTFail("Unhandled error", file: file, line: line)
        fatalError()
    }
    body(URITesterResult(result))
}

final class URITesterResult {
    let result: Result

    init(_ result: Result) {
        self.result = result
    }

    func checkError(_ str: String, file: StaticString = #file, line: UInt = #line) {
        guard case .error(let error) = result else {
            return XCTFail("error not found", file: file, line: line)
        }
        XCTAssertEqual(error, str, file: file, line: line)
    }

    func checkPort(_ port: Int?, file: StaticString = #file, line: UInt = #line) {
        guard case .uri(let uri) = result else {
            return XCTFail("URI not found", file: file, line: line)
        }
        XCTAssertEqual(uri.port, port, file: file, line: line)
    }

    func checkHost(_ str: String, file: StaticString = #file, line: UInt = #line) {
        guard case .uri(let uri) = result else {
            return XCTFail("URI not found", file: file, line: line)
        }
        XCTAssertEqual(uri.host, str, file: file, line: line)
    }

    func checkScheme(_ str: String, file: StaticString = #file, line: UInt = #line) {
        guard case .uri(let uri) = result else {
            return XCTFail("URI not found", file: file, line: line)
        }
        XCTAssertEqual(uri.scheme, str, file: file, line: line)
    }
}

//ftp://ftp.is.co.za/rfc/rfc1808.txt
//http://www.ietf.org/rfc/rfc2396.txt
//ldap://[2001:db8::7]/c=GB?objectClass?one
//mailto:John.Doe@example.com
//news:comp.infosystems.www.servers.unix
//tel:+1-816-555-1212
//telnet://192.0.2.16:80/
//urn:oasis:names:specification:docbook:dtd:xml:4.1.2
