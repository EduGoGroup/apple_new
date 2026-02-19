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

    init() {
        let adminBaseURL = "http://localhost:8081"
        let mobileBaseURL = "http://localhost:9091"

        // Plain network client for auth (no interceptors)
        let plainNetworkClient = NetworkClient()
        let authService = AuthService(
            networkClient: plainNetworkClient,
            adminBaseURL: adminBaseURL
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
            baseURL: mobileBaseURL
        )
        self.dataLoader = DataLoader(
            networkClient: networkClient,
            adminBaseURL: adminBaseURL,
            mobileBaseURL: mobileBaseURL
        )
    }
}
