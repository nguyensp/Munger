//
//  CachingDispatcher.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation
import Combine

/// CoreData Wrapper around URLSessionCombineDispatcher. `RequestDispatcher` conformant.
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
    
    private func shouldCache(_ request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else { return false }
        
        if url.contains("company_tickers_exchange.json") {
            print("📝 Caching enabled for company list")
            return true  // Cache company list - rarely changes
        }
        if url.contains("companyfacts/CIK") {
            print("📝 Caching disabled for financial data")
            return false // Don't cache financial data - needs to be fresh
        }
        print("📝 Default: no caching")
        return false
    }
    
    func dispatch(request: URLRequest) -> AnyPublisher<Data, Error> {
        let cacheKey = request.url?.absoluteString ?? ""
        print("🔍 Attempting to dispatch: \(cacheKey)")
        
        if !shouldCache(request) {
            print("⚡️ Bypassing cache, direct network request")
            return networkDispatcher.dispatch(request: request)
        }
        
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
