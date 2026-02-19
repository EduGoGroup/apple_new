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
        let mobileBaseURL = "http://localhost:9091"
        let adminBaseURL = "http://localhost:9090"

        self.networkClient = NetworkClient()
        self.screenLoader = ScreenLoader(
            networkClient: networkClient,
            baseURL: mobileBaseURL
        )
        self.dataLoader = DataLoader(
            networkClient: networkClient,
            adminBaseURL: adminBaseURL,
            mobileBaseURL: mobileBaseURL
        )
        self.authService = AuthService(
            networkClient: networkClient,
            mobileBaseURL: mobileBaseURL
        )
    }
}
