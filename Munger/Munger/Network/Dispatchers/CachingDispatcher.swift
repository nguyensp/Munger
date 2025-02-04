//
//  CachingDispatcher.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation
import Combine

class CachingDispatcher: RequestDispatcher {
    private let networkDispatcher: URLSessionCombineDispatcher
    private let cache: Cache
    private var cancellables = Set<AnyCancellable>()
    
    init(networkDispatcher: URLSessionCombineDispatcher = URLSessionCombineDispatcher(),
         cache: Cache) {
        print("🔧 CachingDispatcher initialized")
        self.networkDispatcher = networkDispatcher
        self.cache = cache
    }
    
    func dispatch(request: URLRequest) -> AnyPublisher<Data, Error> {
        let cacheKey = request.url?.absoluteString ?? ""
        print("🔍 Attempting to dispatch: \(cacheKey)")
        
        return Future<Data, Error> { [weak self] promise in
            guard let self = self else { return }
            
            Task {
                do {
                    print("📝 Checking cache for: \(cacheKey)")
                    if let cached: Data = try await self.cache.get(for: cacheKey) {
                        print("✅ Cache hit! Using cached data")
                        promise(.success(cached))
                        return
                    }
                    print("❌ Cache miss, fetching from network")
                    
                    self.networkDispatcher.dispatch(request: request)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                case .finished:
                                    print("✅ Network request completed")
                                case .failure(let error):
                                    print("🚨 Network error: \(error)")
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { data in
                                print("📥 Received \(data.count) bytes from network")
                                Task {
                                    do {
                                        try await self.cache.set(data, for: cacheKey)
                                        print("💾 Cached \(data.count) bytes")
                                    } catch {
                                        print("⚠️ Cache save failed: \(error)")
                                    }
                                }
                                promise(.success(data))
                            }
                        )
                        .store(in: &self.cancellables)
                } catch {
                    print("🚨 Cache error: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
