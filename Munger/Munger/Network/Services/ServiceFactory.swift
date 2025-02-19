//
//  ServiceFactory.swift
//  Munger
//
//  Created by Paul Nguyen on 2/18/25.
//

import Foundation

public class ServiceFactory {
    public static let sharedInstance = ServiceFactory()
    
    private let requestDispatcher: RequestDispatcher
    private let authenticationService: AuthenticationService
    
    private init() {
        let cache = CoreDataCache(modelName: "Cache")
        self.requestDispatcher = CachingDispatcher(
            networkDispatcher: URLSessionCombineDispatcher(),
            cache: cache
        )
        self.authenticationService = AuthenticationService()
    }
    
    public func makeCentralIndexKeyNetworkService() -> CentralIndexKeyNetworkService {
        return CentralIndexKeyNetworkService(requestDispatcher: requestDispatcher)
    }
    
    public func makeCompanyFinancialsNetworkService() -> CompanyFinancialsNetworkService {
        return CompanyFinancialsNetworkService(requestDispatcher: requestDispatcher)
    }
    
    public func makeAIChatService(provider: AIProvider = .openai) -> AIChatService {
        return AIChatService(requestDispatcher: requestDispatcher, provider: provider)
    }
    
    public func makeAuthenticationService() -> AuthenticationService {
        return authenticationService
    }
}
