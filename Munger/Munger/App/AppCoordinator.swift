//
//  AppCoordinator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/19/25.
//

/// Injects proper Services into their respective ViewModels using `ServiceFactory`
struct AppCoordinator {
    let serviceFactory: ServiceFactoryProtocol
    
    let watchListManager: WatchListManager
    let userMetricsManager: UserMetricsManager
    let roicManager: ROICManager
    let epsGrowthManager: EPSGrowthManager
    let salesGrowthManager: SalesGrowthManager
    let bookValueGrowthManager: BookValueGrowthManager
    let fcfGrowthManager: FCFGrowthManager
    
    let authViewModel: AuthenticationViewModel
    let companyListViewModel: CompanyListViewModel
    let companyFinancialsViewModel: CompanyFinancialsViewModel
    let watchListViewModel: WatchListViewModel
    let aichatViewModel: AIChatViewModel
    let companyFilingsViewModel: CompanyFilingsViewModel
    
    @MainActor
    init(serviceFactory: ServiceFactoryProtocol) {
        self.serviceFactory = serviceFactory
        
        self.watchListManager = serviceFactory.makeWatchListManager()
        self.userMetricsManager = UserMetricsManager()
        self.roicManager = ROICManager()
        self.epsGrowthManager = EPSGrowthManager()
        self.salesGrowthManager = SalesGrowthManager()
        self.bookValueGrowthManager = BookValueGrowthManager()
        self.fcfGrowthManager = FCFGrowthManager()
        
        self.authViewModel = AuthenticationViewModel()
        self.companyListViewModel = CompanyListViewModel(
            serviceCentralIndexKeys: serviceFactory.makeServiceCentralIndexKeys()
        )
        self.companyFinancialsViewModel = CompanyFinancialsViewModel(serviceCompanyFinancials: serviceFactory.makeServiceCompanyFinancials()
        )
        self.watchListViewModel = WatchListViewModel(
            watchListManager: watchListManager,
            networkService: serviceFactory.makeServiceCentralIndexKeys()
        )
        self.aichatViewModel = AIChatViewModel(
            chatService: serviceFactory.makeServiceAIChat(provider: .openai)
        )
        self.companyFilingsViewModel = CompanyFilingsViewModel(
            serviceSECFilings: serviceFactory.makeServiceSECFilings()
        )
        
        DataMigration.migrateIfNeeded(
            userMetricsManager: userMetricsManager,
            roicManager: roicManager
        )
    }
}
