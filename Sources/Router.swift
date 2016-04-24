//
//  Router.swift
//  URLRouteKit
//
//  Created by 林達也 on 2016/04/23.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


public final class Router {
    
    public enum QueueType {
        case Serial, Concurrent
    }
    
    public enum Error: ErrorType {
        case NotFound(NSURL)
        case InternalError(ErrorType)
    }
    
    private enum State {
        case NotRunning
        case Running
    }
    
    public typealias Handler = (url: NSURL, options: [String: String], animated: Bool) throws -> Response
    
    private var routes: [String: Handler] = [:]
    private var errorHandler: (ErrorType -> Void)?
    
    private var cache: [String: (Handler, [String: String])] = [:]
    private var regexCache: [String: NameCaptureRegex] = [:]
    
    private let queueType: QueueType
    
    private var queue: ArraySlice<NSURL> = []
    
    private var state: State = .NotRunning
    
    public init(_ queueType: QueueType = .Concurrent) {
        self.queueType = queueType
    }
}

public extension Router {
    
    func register(path: String, _ handler: Handler) {
        assert(routes[path] == nil)
        routes[path] = handler
    }
    
    func registerError(handler: ErrorType -> Void) {
        assert(errorHandler == nil)
        errorHandler = handler
    }
    
    func canOpenURL(url: NSURL) -> Bool {
        
        do {
            try handleRequest(url) { _ in }
            return true
        } catch {
            return false
        }
    }
    
    func openURL(url: NSURL, animated: Bool = true) {
        
        func task(completion: () -> Void) {
            state = .Running
            do {
                try handleRequest(url) { handler, result in
                    let response = try handler(url: url, options: result, animated: animated)
                    handleResponse(response) { [weak self] in
                        print("done", url)
                        self?.state = .NotRunning
                        completion()
                    }
                }
            } catch {
                errorHandler?(error)
                state = .NotRunning
                completion()
            }
        }
        
        switch queueType {
        case .Serial where state == .NotRunning:
            task { [weak self] in
                objc_sync_enter(self)
                defer {
                    objc_sync_exit(self)
                }
                if let url = self?.queue.popFirst() {
                    self?.openURL(url)
                }
            }
        case .Serial:
            objc_sync_enter(self)
            defer {
                objc_sync_exit(self)
            }
            queue.append(url)
        case .Concurrent:
            task {}
        }
    }
}

private extension Router {
    
    func handleResponse(response: Response, completion: (() -> Void)) {
        switch response {
        case .None:
            completion()
        case let .URL(url, animated: animated):
            completion()
            openURL(url, animated: animated)
        case let .Async(async):
            async { [weak self] (response: Response) in
                self?.handleResponse(response, completion: completion)
            }
        }
        
    }
    
    func handleRequest(url: NSURL, @noescape callback: (Handler, [String: String]) throws -> Void) throws {
        
        func regex(pattern: String) -> NameCaptureRegex {
            if regexCache[pattern] == nil {
                regexCache[pattern] = try! NameCaptureRegex(pattern: pattern)
            }
            return regexCache[pattern]!
        }
        
        let path = (url.host ?? "") + (url.path ?? "")
        if let (handler, result) = cache[path] {
            try callback(handler, result)
            return
        }
        for (pattern, handler) in routes {
            let regex = regex(pattern)
            if let result = try? regex.match(path) {
                cache[path] = (handler, result)
                try callback(handler, result)
                return
            }
        }
        throw Error.NotFound(url)
    }
    
}
