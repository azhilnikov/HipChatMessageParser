//
//  MessageParser.swift
//  HipChatMessageParser
//
//  Created by Alexey Zhilnikov on 20/03/2016.
//  Copyright © 2016 Alexey Zhilnikov. All rights reserved.
//

import Foundation

private let mentionsSeparator       = "@"
private let nonWordCharacterSet     = NSCharacterSet(charactersInString:
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_").invertedSet
private let emoticonsOpenSeparator  = "("
private let emoticonsCloseSeparator = ")"
private let emoticonsMaximumLength  = 15

private let kMentions               = "mentions"
private let kEmoticons              = "emoticons"
private let kLinks                  = "links"
private let kURL                    = "url"
private let kTitle                  = "title"

class MessageParser: NSObject {
    
    private let message: String
    
    init(message: String) {
        self.message = message
        super.init()
    }
    
    // Parse the message.
    // Return string in JSON format or nil if nothing has been found.
    
    func jsonString() -> String? {
        // Data to be converted into JSON.
        let messageData = NSMutableDictionary()
        
        if let mentions = parseMentions() {
            // Set mentions array.
            messageData.setValue(mentions, forKey: kMentions)
        }
        
        if let emoticons = parseEmoticons() {
            // Set emoticons array.
            messageData.setValue(emoticons, forKey: kEmoticons)
        }
        
        if let urls = parseURLs() {
            var linksArray = [NSMutableDictionary]()
            
            for (url, title) in urls {
                let linksDictionary = NSMutableDictionary()
                linksDictionary.setValue(url, forKey: kURL)
                linksDictionary.setValue(title, forKey: kTitle)
                linksArray.append(linksDictionary)
            }
            
            // Set array with URLs and titles.
            messageData.setValue(linksArray, forKey: kLinks)
        }
        
        // Create JSON object if there is some data.
        if messageData.count > 0 {
            do {
                // Create JSON object.
                let jsonData = try NSJSONSerialization
                    .dataWithJSONObject(messageData, options: .PrettyPrinted)
                
                // Convert JSON into string.
                if let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding) {
                    // NSJSONSerialization converts "/" into "\/". Fix it.
                    let fixedJSONString = jsonString
                        .stringByReplacingOccurrencesOfString("\\/", withString: "/")
                    return fixedJSONString
                }
            }
            catch let jsonError as NSError {
                print("JSON error: " + "\(jsonError.localizedDescription)")
            }
        }
        
        return nil
    }

    // MARK: - Private methods

    // Search for mentions in the message.
    // Return Array<String> containing all mentions found in the message or nil
    // if no mentions have been found.
    
    // Made temporary internal to run tests!!!
    /*private*/ func parseMentions() -> [String]? {
        // Array to store found mentions.
        var mentionsArray = [String]()
        var startIndex = message.startIndex
        
        // Loop through the message to find mentions
        while startIndex < message.endIndex {
            
            // Find a substring starting with "@"
            guard let startRange = message.rangeOfString(mentionsSeparator,
                options: .LiteralSearch,
                range: startIndex..<message.endIndex,
                locale: nil)
            else {
                // There is no a substring starting with "@". Stop search.
                break
            }
            
            // Move index to the character following "@"
            startIndex = startRange.endIndex
            
            // Find first a non-word character from the current index to the end
            // of the message.
            guard let endRange = message.rangeOfCharacterFromSet(nonWordCharacterSet,
                options: .LiteralSearch,
                range: startIndex..<message.endIndex)
            else {
                // There is no a non-word character in the rest of the message.
                // Assume the rest of the message is a "mention".
                // Add it to the array and stop search.
                let mention = message.substringFromIndex(startIndex)
                mentionsArray.append(mention)
                break
            }
            
            // Found a non-word character.
            // Extract a subscting from start index to the index pointing to the
            // non-word character. It is a "mention". Add it to the array.
            // Update start index and continue searching.
            if startIndex != endRange.startIndex {
                let mention = message.substringWithRange(startIndex..<endRange.startIndex)
                mentionsArray.append(mention)
            }
            startIndex = endRange.startIndex
        }
        
        // Return nil if mentions have not been found or array with mentions otherwise.
        return mentionsArray.isEmpty ? nil : mentionsArray
    }
    
    // Search for emoticons in the message.
    // Return Array<String> containing all emoticons found in the message or nil
    // if no emoticons have been found.
    
    // Made temporary internal to run tests!!!
    /*private*/ func parseEmoticons() -> [String]? {
        // Array to store found emoticons.
        var emoticonsArray = [String]()
        var startIndex = message.startIndex
        
        // Loop through the message to find emoticons
        while startIndex < message.endIndex {
            
            // Find "(" starting from the current index to the end of the message.
            guard let startRange = message.rangeOfString(emoticonsOpenSeparator,
                options: .LiteralSearch,
                range: startIndex..<message.endIndex,
                locale: nil)
            else {
                // There is no "(" in the rest of the message. Stop search.
                break
            }
            
            // Found "(". Move index to the next character.
            startIndex = startRange.endIndex
            
            // Find ")" starting from the current index to the end of the message.
            guard let endRange = message.rangeOfString(emoticonsCloseSeparator,
                options: .LiteralSearch,
                range: startIndex..<message.endIndex,
                locale: nil)
            else {
                // There is no ")" in the rest of the message. Stop search.
                break
            }
            
            // Found ")". Check the substring length between "(" and ")".
            let emoticonLength = startIndex.distanceTo(endRange.startIndex)
            if (1...emoticonsMaximumLength).contains(emoticonLength) {
                // Length is correct. Extract a substring. It's an emoticon.
                // Add it to the array.
                let emoticon = message.substringWithRange(startIndex..<endRange.startIndex)
                emoticonsArray.append(emoticon)
            }
            
            // Update start index and continue search.
            startIndex = endRange.endIndex
        }
        
        // Return nil if emoticons have not been found or array with emoticons otherwise.
        return emoticonsArray.isEmpty ? nil : emoticonsArray
    }
    
    // Search for URLs in the message.
    // Return Dictionary<String, String>, where key is a URL and value is a title.
    
    // Made temporary internal to run tests!!!
    /*private*/ func parseURLs() -> [String: String]? {
        // Dictionary containig URLs as keys and titles as values.
        var urlTitleDictionary = [String: String]()
        
        // Create links detector.
        guard let linkDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        else {
            return nil
        }
        
        // Find all URLs in the message.
        let links = linkDetector.matchesInString(message,
            options: [],
            range: NSMakeRange(0, message.characters.count))
        
        for link in links {
            // String containing URL.
            var urlString = (message as NSString).substringWithRange(link.range)
            
            // Maybe it is unnecessary because URL must starts with "http(s)://"
            if !urlString.hasPrefix("http") {
                // Add mandatory prefix
                urlString = "https://" + urlString
            }
            
            // Store link in the dictionary. The title is unknown yet.
            urlTitleDictionary[urlString] = ""
        }
        
        // Loop througn URLs to get titles
        for (urlString, _) in urlTitleDictionary {
            // Extract title string from the content of URL.
            if let url = NSURL(string: urlString),
                let html = try? String(contentsOfURL: url, encoding: NSASCIIStringEncoding),
                let startRange = html.rangeOfString("<title>"),
                let endRange = html.rangeOfString("</title>") {
                    let title = html.substringWithRange(startRange.endIndex..<endRange.startIndex)
                    // Store title in the dictionary.
                    urlTitleDictionary[urlString] = title
                }
        }
        
        // Return nil if no links have been found or
        // dictionary with URLs and titles otherwise.
        return urlTitleDictionary.isEmpty ? nil : urlTitleDictionary
    }
}
