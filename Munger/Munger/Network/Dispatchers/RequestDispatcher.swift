//
//  RequestDispatcher.swift
//  Munger
//
//  Created by Paul Nguyen on 1/30/25.
//

import Foundation
import Combine

public protocol RequestDispatcher {
    func dispatch(request: URLRequest) -> AnyPublisher<Data, Error>
}
