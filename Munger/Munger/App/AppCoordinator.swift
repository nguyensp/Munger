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
    let companyListViewModel: CompanyListViewModel
    let watchListViewModel: WatchListViewModel
    let chatViewModel: ChatViewModel
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
        self.chatViewModel = ChatViewModel(
            chatService: serviceFactory.makeAIChatService(provider: .openai) // Specify provider
        )
        self.companyFilingsViewModel = CompanyFilingsViewModel(
            secFilingNetworkService: serviceFactory.makeSECFilingNetworkService()
        )
    }
}
