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
    func makeServiceSECFilings() -> ServiceSECFilings
    func makeWatchListManager() -> WatchListManager
}

class ServiceFactory: ServiceFactoryProtocol {
    private let requestDispatcher: RequestDispatcher
    
    init() {
        let cache = CoreDataCache(modelName: "Cache")
        self.requestDispatcher = CachingDispatcher(
            networkDispatcher: URLSessionCombineDispatcher(),
            cache: cache
        )
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
    
    func makeServiceSECFilings() -> ServiceSECFilings {
        return ServiceSECFilings(requestDispatcher: requestDispatcher)
    }
    
    func makeWatchListManager() -> WatchListManager {
        WatchListManager()
    }
    
    
}
