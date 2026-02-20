import EduCore
import EduNetwork
import EduDynamicUI
import Observation

@MainActor
@Observable
final class ServiceContainer {
    let networkClient: NetworkClient
    let screenLoader: ScreenLoader
    let dataLoader: DataLoader
    let authService: AuthService
    let apiConfiguration: APIConfiguration

    init(environment: AppEnvironment = .detect()) {
        let config = APIConfiguration.forEnvironment(environment)
        self.apiConfiguration = config

        // Plain network client for auth (no interceptors)
        let plainNetworkClient = NetworkClient()
        let authService = AuthService(
            networkClient: plainNetworkClient,
            adminBaseURL: config.adminBaseURL
        )
        self.authService = authService

        // Authenticated network client with interceptor
        let tokenProvider = SimpleTokenProvider(
            getToken: { await authService.getAccessToken() },
            refresh: { await authService.refreshToken() },
            isExpired: { await authService.isTokenExpired() }
        )
        let authInterceptor = AuthenticationInterceptor.standard(tokenProvider: tokenProvider)
        self.networkClient = NetworkClient(interceptors: [authInterceptor])

        self.screenLoader = ScreenLoader(
            networkClient: networkClient,
            baseURL: config.mobileBaseURL
        )
        self.dataLoader = DataLoader(
            networkClient: networkClient,
            adminBaseURL: config.adminBaseURL,
            mobileBaseURL: config.mobileBaseURL
        )
    }
}
