//
//  MessageParser.swift
//  HipChatMessageParser
//
//  Created by Alexey Zhilnikov on 20/03/2016.
//  Copyright © 2016 Alexey Zhilnikov. All rights reserved.
//

import Foundation

private let mentionsRegExPattern    = "(?<=@).*?(?=\\W|$)"
private let emoticonsRegExPattern   = "(?<=\\().*?(?=\\))"
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
    
    func jsonString(completion: (data: String?) -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        
            // Data to be converted into JSON.
            let messageData = NSMutableDictionary()
            
            if let mentions = self.parseMentions() {
                // Set mentions array.
                messageData.setValue(mentions, forKey: kMentions)
            }
            
            if let emoticons = self.parseEmoticons() {
                // Set emoticons array.
                messageData.setValue(emoticons, forKey: kEmoticons)
            }
            
            if let urls = self.parseURLs() {
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
                    // Create JSON object.
                guard let jsonData = try? NSJSONSerialization.dataWithJSONObject(messageData,
                                                                                 options: .PrettyPrinted)
                else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(data: nil)
                    })
                    return
                }
                    
                // Convert JSON into string.
                if let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding) {
                    // NSJSONSerialization converts "/" into "\/". Fix it.
                    let fixedJSONString = jsonString
                        .stringByReplacingOccurrencesOfString("\\/", withString: "/")
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(data: fixedJSONString)
                    })
                    return
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                completion(data: nil)
            })
            return
        })
    }

    // MARK: - Private methods

    // Search for mentions in the message.
    // Return Array<String> containing all mentions found in the message or nil
    // if no mentions have been found.
    
    // Made temporary internal to run tests!!!
    /*private*/ func parseMentions() -> [String]? {
        return matchesWithPattern(mentionsRegExPattern)
    }
    
    // Search for emoticons in the message.
    // Return Array<String> containing all emoticons found in the message or nil
    // if no emoticons have been found.
    
    // Made temporary internal to run tests!!!
    /*private*/ func parseEmoticons() -> [String]? {
        if let matches = self.matchesWithPattern(emoticonsRegExPattern)
            where !matches.isEmpty {
            return  matches.filter{$0.characters.count <= emoticonsMaximumLength}
        }
        return nil
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
            
            // Maybe it is unnecessary because URL must start with "http(s)://"
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
    
    // Search for matches in the message using given pattern.
    // Return Array<String> containing all matches found in the message or nil
    // if no matches have been found.
    
    private func matchesWithPattern(pattern: String) -> [String]? {
        // Create a regular expression
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: .CaseInsensitive)
        else {
            // Wrong regular expression
            return nil
        }
        
        // Find all matches in the message
        let matches = regex.matchesInString(message,
                                            options: [],
                                            range: NSMakeRange(0, message.characters.count))
        
        return matches.isEmpty ? nil : matches.map{
            (self.message as NSString).substringWithRange($0.range)
        }
    }
}
