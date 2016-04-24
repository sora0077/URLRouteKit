//
//  NameCaptureRegex.swift
//  URLRouteKit
//
//  Created by 林達也 on 2016/04/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


final class NameCaptureRegex {
    
    enum Error: ErrorType {
        case NotFound
    }
    
    private var _regex: NSRegularExpression!
    private var _capturedKeys: [String] = []
    
    init(pattern: String) throws {
        
        let regex = try NSRegularExpression(pattern: "\\(\\?<([a-zA-Z_][0-9a-zA-Z_]+)>(.+?)\\)", options: [])
        
        _capturedKeys = regex.matchesInString(pattern, options: [], range: NSMakeRange(0, pattern.utf8.count)).map {
            let range = $0.rangeAtIndex(1)
            let start = pattern.utf16.startIndex.advancedBy(range.location)
            let end = start.advancedBy(range.length)
            return String(pattern.utf16[start..<end])
        }
        
        let formattedPattern = regex
            .stringByReplacingMatchesInString(
                pattern, options: [], range: NSMakeRange(0, pattern.utf16.count), withTemplate: "($2)")
            .stringByReplacingOccurrencesOfString("((", withString: "(")
            .stringByReplacingOccurrencesOfString("))", withString: ")")
        print(formattedPattern)
        
        _regex = try NSRegularExpression(pattern: formattedPattern, options: [])
    }
    
    func match(target: String) throws -> [String: String] {
        
        let results = _regex.matchesInString(target, options: [], range: NSMakeRange(0, target.utf16.count))
        if results.isEmpty {
            throw Error.NotFound
        }
        var dict: [String: String] = [:]
        for i in 1..<results[0].numberOfRanges {
            let range = results[0].rangeAtIndex(i)
            let start = target.utf16.startIndex.advancedBy(range.location)
            let end = start.advancedBy(range.length)
            dict[_capturedKeys[i-1]] = String(target.utf16[start..<end])
        }
        return dict
    }
}
