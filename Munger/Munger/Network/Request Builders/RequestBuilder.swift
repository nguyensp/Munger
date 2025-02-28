//
//  RequestBuilder.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation

/// Builds URLRequests to be dispatched
struct RequestBuilder {
    /**
     Creates a URLRequest with the specified configurations.
     - Parameters:
        - url: The URL for the request
        - method: The HTTP method for the request (e.g. GET, POST).
        - headers: Optional HTTP headers for the request.
        - body: Optional body data for the request.
     - Returns: A configured URLRequest object.
     This method is used internally to create requests with custom configurations.
     */
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
    
    /**
     Creates a GET URLRequest with the specified URL and optional headers.
     - Parameters:
        - url: The URL for the request.
        - headers: Optional HTTP headers for the request.
     - Returns: A configured GET URLRequest object.
     */
    static func createGetRequest(
        from url: URL,
        header: [String: String]? = nil
    ) -> URLRequest {
        return createRequest(url: url, method: "GET", header: header)
    }
}
