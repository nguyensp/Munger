//
//  AppCoordinator.swift
//  Munger
//
//  Created by Paul Nguyen on 2/19/25.
//

/// Centralizes the depedency injection of specific services into their respective ViewModels
struct AppCoordinator {
    let serviceFactory: ServiceFactoryProtocol
    
    let authViewModel: AuthenticationViewModel
    
    let watchListManager: WatchListManager
    let roicManager: ROICManager
    let epsGrowthManager: EPSGrowthManager
    let salesGrowthManager: SalesGrowthManager
    let equityGrowthManager: EquityGrowthManager
    let freeCashFlowManager: FreeCashFlowManager
    
    let companyListViewModel: CompanyListViewModel
    let watchListViewModel: WatchListViewModel
    let chatViewModel: ChatViewModel
    let companyFilingsViewModel: CompanyFilingsViewModel
    
    @MainActor
    init(serviceFactory: ServiceFactoryProtocol) {
        self.serviceFactory = serviceFactory
        self.authViewModel = serviceFactory.makeAuthenticationViewModel()
        self.watchListManager = serviceFactory.makeWatchListManager()
        
        /// Margin of Safety Calculators
        self.roicManager = ROICManager()
        self.epsGrowthManager = EPSGrowthManager()
        self.salesGrowthManager = SalesGrowthManager()
        self.equityGrowthManager = EquityGrowthManager()
        self.freeCashFlowManager = FreeCashFlowManager()
        
        self.companyListViewModel = CompanyListViewModel(
            centralIndexKeyNetworkService: serviceFactory.makeCentralIndexKeyNetworkService()
        )
        self.watchListViewModel = WatchListViewModel(
            watchListManager: watchListManager,
            networkService: serviceFactory.makeCentralIndexKeyNetworkService()
        )
        self.chatViewModel = ChatViewModel(
            chatService: serviceFactory.makeAIChatService(provider: .openai)
        )
        self.companyFilingsViewModel = CompanyFilingsViewModel(
            secFilingNetworkService: serviceFactory.makeSECFilingNetworkService()
        )
    }
}
