# Ape

A Swift library to make API requests easily and expressively.

## Example Usage

### Basic

    import Ape
    import Foundation // for NSURL

    let url = NSURL(string: "http://google.com")!

    _ = Ape(method: .Get, url: url, body: .None) {
        resp in
        print("got a response")
    }

    print("sending")

    sleep(10) // wait for async operation to complete (assuming you're running this on command line.
    
### Methods

Ape supports Get, Post, Put and Delete.

### Bodies

Ape's Body enum can contain JSON objects, NSData, or nothing.

Supply a JSON body:

       let json = ["name": "world", "count": 10]
       _ = Ape(method: .Get, url: url, body: .JSON(json)) { resp in }
       
Supply an NSData body:

       let data = "Please feed me tacos".dataUsingEncoding(NSUTF8StringEncoding)
       _ = Ape(method: .Get, url: url, body: .Data(data)) { resp in }

### Responses

Ape's  APIResponse struct has three public properties:

        public let body: Body
        public let urlResponse: NSHTTPURLResponse?
        public let error: ErrorType?
        
`body` is just like the body when you're sending a request, either `.None`, `.JSON` or `.Data`. To unpack it, you can use the usual switch statement:

    switch resp.body {
        case .JSON(let json):
            break
        case .Data(let data):
            break
        case .None:
            break
    }

You can also use conditional pattern matching to check for a single case:

    if case .JSON(let json) = resp.body { // also works in a gaurd statement
        print("json is \(json)")
    }

### init methods

Ape has two init methods:

  1. `init(method: Method = .Get, request: NSURLRequest, body: Body = .None, completion: ResponseClosure)`
  2. `init(method: Method = .Get, url: NSURL, auth: AuthClosure = { _ in }, body: Body = .None, completion: ResponseClosure)`
  
As you can see, most of the parameters have default values, so you can omit them if you are ok with the defaults.

    Ape(request: request) {
        resp in
        // ...
    }
    
or

    Ape(url: request) {
        resp in
        // ...
    }
    
AuthClosure is a typealias of the closure type `(NSMutableURLRequest)->(Void)`, a closure that takes in a mutable url request and modifies it to contain auth data (set http headers, etc).

## Installation

### Swift Package Manager

Add Later to your `Package.swift` file:

    import PackageDescription

    let package = Package(
        name: "YourPackageName",
        dependencies: [
            .Package(url: "https://github.com/coryalder/Ape.git", majorVersion: 0),
        ]
    )

