//
//  HipChatMessageParserTests.swift
//  HipChatMessageParserTests
//
//  Created by Alexey Zhilnikov on 20/03/2016.
//  Copyright © 2016 Alexey Zhilnikov. All rights reserved.
//

import XCTest
@testable import HipChatMessageParser

class HipChatMessageParserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    // To successfully run this test remove private access level for
    // parseMentions, parseEmoticons and parseURLs methods!!!
    
    func testMessageParser() {
        let message1 = "@bob/ Hi! @paul$% Good morning (success)"
        let expectedMentions = ["bob", "paul"]
        
        let parser1 = MessageParser(message: message1)
        if let mentions = parser1.parseMentions() {
            XCTAssertEqual(expectedMentions, mentions, "Mentions parsing error!")
        }
        else {
            XCTAssert(false, "Mentions not found!")
        }
        
        let message2 = "(haha-lala-haha-lala)@bob Hi! (smile) @paul Good morning (megusta)(coffee)"
        let expectedEmoticons = ["smile", "megusta", "coffee"]
        
        let parser2 = MessageParser(message: message2)
        if let emoticons = parser2.parseEmoticons() {
            XCTAssertEqual(expectedEmoticons, emoticons, "Emoticons parsing error!")
        }
        else {
            XCTAssert(false, "Emoticons not found!")
        }
        
        let message3 = "@chris https://google.com http://www.nbcolympics.com (cool)"
        let expectedURLs = ["https://google.com": "Google",
                            "http://www.nbcolympics.com": "NBC Olympics | Home of the 2016 Olympic Games in Rio"]
        
        let parser3 = MessageParser(message: message3)
        if let urls = parser3.parseURLs() {
            XCTAssertEqual(expectedURLs, urls, "URLs parsing error!")
        }
        else {
            XCTAssert(false, "URLs not found!")
        }
    }
}
