//
//  RequestBuilderTests.swift
//  MungerTests
//
//  Created by Paul Nguyen on 2/12/25.
//

import Foundation
import XCTest
@testable import Munger

class RequestBuilderTests: XCTestCase {
    
    // MARK: - createRequest Tests
    
    // Test Case 1: Create a request with a valid URL and method
    func testCreateRequest_WithValidURLAndMethod() {
        let url = URL(string: "https://example.com")!
        let method = "GET"
        
        let request = RequestBuilder.createRequest(url: url, method: method)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
    }
    
    // Test Case 2: Create a request with headers
    func testCreateRequest_WithHeaders() {
        let url = URL(string: "https://example.com")!
        let method = "POST"
        let headers = ["Content-Type": "application/json"]
        
        let request = RequestBuilder.createRequest(url: url, method: method, header: headers)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(request.allHTTPHeaderFields, headers)
    }
    
    // Test Case 3: Create a request with a body
    func testCreateRequest_WithBody() {
        let url = URL(string: "https://example.com")!
        let method = "PUT"
        let body = "Request Body".data(using: .utf8)
        
        let request = RequestBuilder.createRequest(url: url, method: method, body: body)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(request.httpBody, body)
    }
    
    // Test Case 4: Create a request with all parameters (URL, method, headers, and body)
    func testCreateRequest_WithAllParameters() {
        let url = URL(string: "https://example.com")!
        let method = "PATCH"
        let headers = ["Content-Type": "application/json"]
        let body = "Request Body".data(using: .utf8)
        
        let request = RequestBuilder.createRequest(url: url, method: method, header: headers, body: body)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(request.allHTTPHeaderFields, headers)
        XCTAssertEqual(request.httpBody, body)
    }
    
    // Test Case 5: Create a request with missing headers
    func testCreateRequest_WithMissingHeaders() {
        let url = URL(string: "https://example.com")!
        let method = "DELETE"
        
        let request = RequestBuilder.createRequest(url: url, method: method)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }
    
    // Test Case 6: Create a request with missing body
    func testCreateRequest_WithMissingBody() {
        let url = URL(string: "https://example.com")!
        let method = "HEAD"
        
        let request = RequestBuilder.createRequest(url: url, method: method)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertNil(request.httpBody)
    }
    
    // MARK: - createGetRequest Tests
    
    // Test Case 7: Create a get request with a valid URL.
    func testCreateGetRequest_WithValidURL() {
        let url = URL(string: "https://example.com")!
        
        let request = RequestBuilder.createGetRequest(from: url)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
    }
    
    // Test Case 8: Create a get request with headers
    func testCreateGetRequest_WithHeaders() {
        let url = URL(string: "https://example.com")!
        let headers = ["Accept": "application/json"]
        
        let request = RequestBuilder.createGetRequest(from: url, header: headers)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields, headers)
    }
    
    // Test Case 9: Create a get request with missing headers
    func testCreateGetRequest_WithMissingHeaders() {
        let url = URL(string: "https://example.com")!
        
        let request = RequestBuilder.createGetRequest(from: url)
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
    }
}

