//
//  JeevesTests.swift
//  Vapor
//
//  Created by Logan Wright on 3/12/16.
//  Copyright © 2016 Tanner Nelson. All rights reserved.
//

import Foundation
import XCTest

@testable import Vapor
@testable import C7

final class TestHTTPStream: HTTPStream {
    enum Error: ErrorProtocol {
        case Closed
    }

    var buffer: Data

    init() {
        buffer = []
    }

    static func makeStream() -> TestHTTPStream {
        return TestHTTPStream()
    }

    func accept(max connectionCount: Int, handler: (HTTPStream -> Void)) throws {

    }

    func bind(to ip: String?, on port: Int) throws {


    }

    func listen() throws {
        
    }

    var closed: Bool = false

    func close() -> Bool {
        if !closed {
            closed = true
            return true
        }
        return false
    }

    func receive(max byteCount: Int) throws -> Data {
        if buffer.count == 0 {
            close()
            return []
        }

        if byteCount >= buffer.count {
            close()
            let data = buffer
            buffer = []
            return data
        }

        let data = buffer.bytes[0..<byteCount]
        buffer.bytes.removeFirst(byteCount)

        let result = Data(data)
        return result
    }

    func send(data: Data) throws {
        closed = false
        buffer.append(contentsOf: data)
    }

    func flush() throws {

    }

}

class HTTPStreamTests: XCTestCase {

    static var allTests: [(String, HTTPStreamTests -> () throws -> Void)] {
        return [
           ("testStream", testStream)
        ]
    }

    func testStream() throws {
        let stream = TestHTTPStream.makeStream()

        //MARK: Create Request
        let content = "{\"hello\": \"world\"}"

        var data = "POST /json HTTP/1.1\r\n"
        data += "Accept-Encoding: gzip, deflate\r\n"
        data += "Accept: */*\r\n"
        data += "Accept-Language: en-us\r\n"
        data += "Cookie: 1=1\r\n"
        data += "Cookie: 2=2\r\n"
        data += "Content-Type: application/json\r\n"
        data += "Content-Length: \(content.characters.count)\r\n"
        data += "\r\n"
        data += content

        //MARK: Send Request
        try stream.send(data)

        //MARK: Read Request
        let request: Request
        do {
            request = try stream.receive()
        } catch {
            XCTFail("Error receiving from stream: \(error)")
            return
        }

        //MARK: Verify Request
        XCTAssert(request.method == Request.Method.post, "Incorrect method \(request.method)")
        XCTAssert(request.uri.path == "/json", "Incorrect path \(request.uri.path)")
        XCTAssert(request.version.major == 1 && request.version.minor == 1, "Incorrect version")
        XCTAssert(request.headers["cookie"].count == 2, "Incorrect cookies count")
        XCTAssert(request.cookies["1"] == "1" && request.cookies["2"] == "2", "Cookies not parsed")
        XCTAssert(request.data["hello"]?.string == "world")


        //MARK: Create Response
        var response = Response(status: .enhanceYourCalm, headers: [
            "Test": ["123", "456"],
            "Content-Type": "text/plain"
        ], body: { stream in
            try stream.send("Hello, world")
        })
        response.cookies["key"] = "val"

        //MARK: Send Response
        try stream.send(response, keepAlive: true)

        //MARK: Read Response
        do {
            let data = try stream.receive(max: Int.max)
            print(data)

            let expected = "HTTP/1.1 420 Enhance Your Calm\r\nConnection: keep-alive\r\nContent-Type: text/plain\r\nSet-Cookie: key=val\r\nTest: 123\r\nTest: 456\r\nTransfer-Encoding: chunked\r\n\r\nHello, world"

            //MARK: Verify Response
            XCTAssert(data == expected.data)
        } catch {
            XCTFail("Could not parse response string \(error)")
        }

    }
}