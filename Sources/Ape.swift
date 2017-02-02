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
        case Data(Data)
        case JSON(AnyObject)
        case None
    }
    
    public struct APIResponse {
        public let body: Body
        public let urlResponse: HTTPURLResponse?
        public let error: Error?
    }
    
    public typealias ResponseClosure = (APIResponse)->(Void)
    public typealias AuthClosure = (URLRequest)->(URLRequest)
    
    public let task: URLSessionDataTask
    
    // pass in an auth closure, to mutate the request before sending.
    
    public init(method: Method = .Get, url: URL, auth: AuthClosure = { $0 }, body: Body = .None, completion: ResponseClosure) {

        let request = URLRequest(url: url)
        let mutatedRequest = auth(request)
        
        self.init(method: method, request: mutatedRequest, body: body, completion: completion)
    }
    
    
    public init(method: Method = .Get, request: URLRequest, body: Body = .None, completion: ResponseClosure) {
        
        var req: URLRequest = request
        
        req.httpMethod = method.rawValue
        
        switch body {
        case .Data(let data):
            req.httpBody = data
        case .JSON(let obj):
            req.httpBody = try? JSONSerialization.data(withJSONObject: obj, options: [])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .None:
            req.httpBody = nil
        }
        
        self.task = URLSession.shared.dataTask(with: request) {
            data, resp, err in
            
            var outBody: Body = .None
            
            if let data = data {
                outBody = .Data(data) // we've at least got data
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    outBody = .JSON(json)
                }
                
            }
            
            #if DEBUG
            print("\(resp?.URL!): \((resp as? HTTPURLResponse)?.statusCode ?? 0)")
            #endif

            completion(APIResponse(body: outBody, urlResponse: resp as? HTTPURLResponse, error: err))

        }

        task.resume()
    }
}


extension HTTPURLResponse {
    var asError: NSError? {
        guard self.statusCode != 200 else {
            return  nil
        }
        
        return NSError(domain: "HTTP", code: self.statusCode, userInfo: nil)
    }
}
