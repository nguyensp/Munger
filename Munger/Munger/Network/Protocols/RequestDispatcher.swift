//
//  RequestDispatcher.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation
import Combine

/// A protocol for asynchronous networking using Combine
public protocol RequestDispatcher {
    /**
     Dispatches a URL request and returns a publisher.
     - Parameters:
        - request: THe URLRequest object representing the network request.
     - Returns: A publisher that emits `Data` on success or an `Error` on failure.
     
     Conformance implies a Combine publisher to handle asynchronous networking operations.
     */
    func dispatch(request: URLRequest) -> AnyPublisher<Data, Error>
}
