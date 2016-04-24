//
//  ResponseType.swift
//  URLRouteKit
//
//  Created by 林達也 on 2016/04/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


public enum Response {
    
    case None
    
    case URL(NSURL, animated: Bool)

    case Async((Response -> Void) -> Void)
    
    public init(async: (Response -> Void) -> Void) {
        self = .Async(async)
    }
}

extension Response: NilLiteralConvertible {
    
    public init(nilLiteral: ()) {
        self = .None
    }
}
