import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    @Published var token: String?

    func signOut() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            token = nil
        }
    }
}

@main
struct FakeStoreFrontendApp: App {
    @StateObject private var session = AppSession()
    private let dataManager: any StoreDataManaging = StoreDataManager()

    var body: some Scene {
        WindowGroup {
            AppRootView(dataManager: dataManager, session: session)
                .preferredColorScheme(.light)
        }
    }
}

struct AppRootView: View {
    let dataManager: any StoreDataManaging
    @ObservedObject var session: AppSession

    var body: some View {
        Group {
            if session.token == nil {
                LoginView(dataManager: dataManager) { token in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        session.token = token
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                StoreTabView(dataManager: dataManager, onSignOut: session.signOut)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: session.token != nil)
    }
}
