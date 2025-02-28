//
//  AppCoordinator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/19/25.
//

struct AppCoordinator {
    let serviceFactory: ServiceFactoryProtocol
    let authViewModel: AuthenticationViewModel
    let watchListManager: WatchListManager
    
    let userMetricsManager: UserMetricsManager
    let roicManager: ROICManager
    
    let companyListViewModel: CompanyListViewModel
    let watchListViewModel: WatchListViewModel
    let aichatViewModel: AIChatViewModel
    let companyFilingsViewModel: CompanyFilingsViewModel
    
    @MainActor
    init(serviceFactory: ServiceFactoryProtocol) {
        self.serviceFactory = serviceFactory
        self.authViewModel = serviceFactory.makeAuthenticationViewModel()
        self.watchListManager = serviceFactory.makeWatchListManager()
        self.companyListViewModel = CompanyListViewModel(
            centralIndexKeyNetworkService: serviceFactory.makeCentralIndexKeyNetworkService()
        )
        self.watchListViewModel = WatchListViewModel(
            watchListManager: watchListManager,
            networkService: serviceFactory.makeCentralIndexKeyNetworkService()
        )
        self.aichatViewModel = AIChatViewModel(
            chatService: serviceFactory.makeAIChatService(provider: .openai)
        )
        self.companyFilingsViewModel = CompanyFilingsViewModel(
            secFilingNetworkService: serviceFactory.makeSECFilingNetworkService()
        )
        
        // Remove initialization of the original manager
        // self.metricsWatchListManager = MetricsWatchListManager()
        
        // Initialize new managers
        self.userMetricsManager = UserMetricsManager()
        self.roicManager = ROICManager()
        
        // The migration can be kept for users upgrading from earlier versions
        DataMigration.migrateIfNeeded(
            userMetricsManager: userMetricsManager,
            roicManager: roicManager
        )
    }
}
