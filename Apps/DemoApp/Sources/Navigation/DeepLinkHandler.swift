import Foundation
import Observation

struct DeepLink: Equatable, Sendable, Identifiable {
    let screenKey: String
    let params: [String: String]

    var id: String {
        if params.isEmpty {
            return screenKey
        }
        let query = params
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return "\(screenKey)?\(query)"
    }
}

@MainActor
@Observable
final class DeepLinkHandler {

    var pendingDeepLink: DeepLink?

    func handle(url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "edugo",
              components.host == "screen" else {
            return nil
        }

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty else { return nil }

        var params: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let value = item.value {
                params[item.name] = value
            }
        }

        return DeepLink(screenKey: path, params: params)
    }

    func storePending(url: URL) {
        pendingDeepLink = handle(url: url)
    }

}
