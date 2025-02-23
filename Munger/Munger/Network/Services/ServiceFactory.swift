//
//  ServiceFactory.swift
//  Munger
//
//  Created by Paul Nguyen on 2/18/25.
//

protocol ServiceFactoryProtocol {
    func makeCentralIndexKeyNetworkService() -> CentralIndexKeyNetworkService
    func makeCompanyFinancialsNetworkService() -> CompanyFinancialsNetworkService
    func makeAIChatService(provider: AIProvider) -> AIChatService
    func makeAuthenticationService() -> AuthenticationService
    @MainActor func makeAuthenticationViewModel() -> AuthenticationViewModel
    func makeWatchListManager() -> WatchListManager
    func makeSECFilingNetworkService() -> SECFilingNetworkService
}

class ServiceFactory: ServiceFactoryProtocol {
    private let requestDispatcher: RequestDispatcher
    private let authenticationService: AuthenticationService
    
    init() {
        let cache = CoreDataCache(modelName: "Cache")
        self.requestDispatcher = CachingDispatcher(
            networkDispatcher: URLSessionCombineDispatcher(),
            cache: cache
        )
        self.authenticationService = AuthenticationService()
    }
    
    func makeCentralIndexKeyNetworkService() -> CentralIndexKeyNetworkService {
        CentralIndexKeyNetworkService(requestDispatcher: requestDispatcher)
    }
    
    func makeCompanyFinancialsNetworkService() -> CompanyFinancialsNetworkService {
        CompanyFinancialsNetworkService(requestDispatcher: requestDispatcher)
    }
    
    func makeAIChatService(provider: AIProvider = .openai) -> AIChatService {
        AIChatService(requestDispatcher: requestDispatcher, provider: provider)
    }
    
    func makeAuthenticationService() -> AuthenticationService {
        authenticationService
    }
    
    @MainActor
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        AuthenticationViewModel(authService: authenticationService)
    }
    
    func makeWatchListManager() -> WatchListManager {
        WatchListManager()
    }
    
    func makeSECFilingNetworkService() -> SECFilingNetworkService {
        return SECFilingNetworkService(requestDispatcher: requestDispatcher)
    }
}
