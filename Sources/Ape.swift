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
        public let body: Body
        public let urlResponse: NSHTTPURLResponse?
        public let error: ErrorProtocol?
    }
    
    public typealias ResponseClosure = (APIResponse)->(Void)
    public typealias AuthClosure = (NSMutableURLRequest)->(Void)
    
    public let task: NSURLSessionDataTask
    
    // pass in an auth closure, to mutate the request before sending.
    
    public init(method: Method = .Get, url: NSURL, auth: AuthClosure = { _ in }, body: Body = .None, completion: ResponseClosure) {

        let request = NSMutableURLRequest(url: url)
        auth(request)
        
        self.init(method: method, request: request, body: body, completion: completion)
    }
    
    
    public init(method: Method = .Get, request: NSURLRequest, body: Body = .None, completion: ResponseClosure) {
        
        let req: NSMutableURLRequest = (request as? NSMutableURLRequest) ?? request.mutableCopy() as! NSMutableURLRequest
        
        req.httpMethod = method.rawValue
        
        switch body {
        case .Data(let data):
            req.httpBody = data
        case .JSON(let obj):
            req.httpBody = try? NSJSONSerialization.data(withJSONObject: obj, options: [])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .None:
            req.httpBody = nil
        }
        
        self.task = NSURLSession.shared().dataTask(with: request) {
            data, resp, err in
            
            var outBody: Body = .None
            
            if let data = data {
                outBody = .Data(data) // we've at least got data
                
                if let json = try? NSJSONSerialization.jsonObject(with: data, options: []) {
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