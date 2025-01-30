//
//  RequestBuilder.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation

struct RequestBuilder {
    static func createRequest(
        url: URL,
        method: String,
        header: [String: String]? = nil,
        body: Data? = nil
    ) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = header
        urlRequest.httpBody = body
        return urlRequest
    }
    
    static func createGetRequest(
        from url: URL,
        header: [String: String]? = nil
    ) -> URLRequest {
        return createRequest(url: url, method: "GET", header: header)
    }
}
