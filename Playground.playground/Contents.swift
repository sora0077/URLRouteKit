//: Playground - noun: a place where people can play

import UIKit
import XCPlayground
@testable import URLRouteKit

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


let router = Router(.Serial)

var id = 0
router.register("^/users/(?<user_id>[0-9]+)$") { url, options, animated in
    
    url
    options
    animated
    return Response { completion in
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_main_queue()) {
            if id > 10 {
                completion(nil)
            } else {
                id += 1
                completion(.URL(NSURL(string: "/users/\(id)")!, animated: animated))
            }
        }
    }
}

router.register("^/(?<sns_type>(twitter|facebook))$") { url, options, animated in
 
    url
    options
    animated
    return nil
}

router.registerError { error in
    print(error)
    return nil
}

router.openURL(NSURL(string: "/twitter/")!)
router.openURL(NSURL(string: "/users/2")!)
router.openURL(NSURL(string: "/users/23d")!)
router.openURL(NSURL(string: "/facebook/")!)




//let regex = try! NSRegularExpression(pattern: "^/(twitter|facebook)/$", options: [])
//let str = "/twitter"
//regex.matchesInString(str, options: [], range: NSMakeRange(0, str.utf16.count))

//let regex = try! NameCaptureRegex(pattern: "^/(?<sns_type>(twitter|facebook))$")
//try? regex.match("/twitter")
