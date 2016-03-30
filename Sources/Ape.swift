//
//  Ape.swift
//
//  Created by Cory Alder on 2016-02-22.
//  Copyright © 2016 Cory Alder. All rights reserved.
//

import Foundation


public struct Ape {
    public enum Method: String {
        case Get = "GET"
        case Post = "POST"
        case Put = "PUT"
        case Delete = "DELETE"
    }
    
    public enum Body {
        case Data(NSData)
        case JSON(AnyObject)
        case None
    }
    
    public struct APIResponse {
        let body: Body
        let urlResponse: NSHTTPURLResponse?
        let error: ErrorType?
    }
    
    public let task: NSURLSessionDataTask
    
    typealias ResponseClosure = (APIResponse)->(Void)
    typealias AuthClosure = (NSMutableURLRequest)->(Void)
    
    // pass in an auth closure, to mutate the request before sending.
    
    public init(method: Method = .Get, url: NSURL, auth: AuthClosure = { _ in }, body: Body = .None, completion: ResponseClosure) {

        let request = NSMutableURLRequest(URL: url)
        auth(request)
        
        self.init(method: method, request: request, body: body, completion: completion)
    }
    
    
    public init(method: Method = .Get, request: NSURLRequest, body: Body = .None, completion: ResponseClosure) {
        
        let req = (request as? NSMutableURLRequest) ?? request.mutableCopy() as! NSMutableURLRequest
        
        req.HTTPMethod = method.rawValue
        
        switch body {
        case .Data(let data):
            req.HTTPBody = data
        case .JSON(let obj):
            req.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(obj, options: [])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .None:
            req.HTTPBody = nil
        }
        
        self.task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, resp, err in
            
            var outBody: Body = .None
            
            if let data = data {
                outBody = .Data(data) // we've at least got data
                
                if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
                    outBody = .JSON(json)
                }
                
            }
            
            #if DEBUG
            print("\(resp?.URL!): \((resp as? NSHTTPURLResponse)?.statusCode ?? 0)")
            #endif

            completion(APIResponse(body: outBody, urlResponse: resp as? NSHTTPURLResponse, error: err))

        }

        task.resume()
    }
}


extension NSHTTPURLResponse {
    var asError: NSError? {
        guard self.statusCode != 200 else {
            return  nil
        }
        
        return NSError(domain: "HTTP", code: self.statusCode, userInfo: nil)
    }
}