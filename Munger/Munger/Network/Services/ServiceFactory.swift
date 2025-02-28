//
//  ServiceFactory.swift
//  Munger
//
//  Created by Paul Nguyen on 2/18/25.
//

protocol ServiceFactoryProtocol {
    func makeServiceCentralIndexKeys() -> ServiceCentralIndexKeys
    func makeServiceCompanyFinancials() -> ServiceCompanyFinancials
    func makeServiceAIChat(provider: AIProvider) -> ServiceAIChat
    func makeServiceAuthentication() -> ServiceAuthentication
    @MainActor func makeAuthenticationViewModel() -> AuthenticationViewModel
    func makeWatchListManager() -> WatchListManager
    func makeServiceSECFilings() -> ServiceSECFilings
}

class ServiceFactory: ServiceFactoryProtocol {
    private let requestDispatcher: RequestDispatcher
    private let serviceAuthentication: ServiceAuthentication
    
    init() {
        let cache = CoreDataCache(modelName: "Cache")
        self.requestDispatcher = CachingDispatcher(
            networkDispatcher: URLSessionCombineDispatcher(),
            cache: cache
        )
        self.serviceAuthentication = ServiceAuthentication()
    }
    
    func makeServiceCentralIndexKeys() -> ServiceCentralIndexKeys {
        ServiceCentralIndexKeys(requestDispatcher: requestDispatcher)
    }
    
    func makeServiceCompanyFinancials() -> ServiceCompanyFinancials {
        ServiceCompanyFinancials(requestDispatcher: requestDispatcher)
    }
    
    func makeServiceAIChat(provider: AIProvider = .openai) -> ServiceAIChat {
        ServiceAIChat(requestDispatcher: requestDispatcher, provider: provider)
    }
    
    func makeServiceAuthentication() -> ServiceAuthentication {
        serviceAuthentication
    }
    
    @MainActor
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        AuthenticationViewModel(authService: serviceAuthentication)
    }
    
    func makeWatchListManager() -> WatchListManager {
        WatchListManager()
    }
    
    func makeServiceSECFilings() -> ServiceSECFilings {
        return ServiceSECFilings(requestDispatcher: requestDispatcher)
    }
}
