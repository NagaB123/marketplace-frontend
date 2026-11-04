import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let dataManager: any StoreDataManaging
    private let onLogin: (String) -> Void

    init(dataManager: any StoreDataManaging, onLogin: @escaping (String) -> Void) {
        self.dataManager = dataManager
        self.onLogin = onLogin
    }

    func signIn() async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Enter your username and password to continue."
            return
        }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token = try await dataManager.login(username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            onLogin(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let dataManager: any StoreDataManaging

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
    }

    func load(category: String? = nil) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let category {
                products = try await dataManager.fetchProducts(category: category)
            } else {
                products = try await dataManager.fetchProducts()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class CategoryViewModel: ObservableObject {
    @Published private(set) var categories: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let dataManager: any StoreDataManaging

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await dataManager.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let dataManager: any StoreDataManaging

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
    }

    func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            products = []
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            products = try await dataManager.searchProducts(query: term)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let productID: Int
    private let dataManager: any StoreDataManaging

    init(productID: Int, dataManager: any StoreDataManaging) {
        self.productID = productID
        self.dataManager = dataManager
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            product = try await dataManager.fetchProduct(id: productID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class EnquiryViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var message = ""
    @Published var productID = ""
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let dataManager: any StoreDataManaging

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
    }

    func submit() async {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanEmail.isEmpty, !cleanMessage.isEmpty else {
            errorMessage = "Please complete your name, email, and message."
            successMessage = nil
            return
        }
        guard cleanEmail.contains("@"), cleanEmail.split(separator: "@").last?.contains(".") == true else {
            errorMessage = "Enter a valid email address."
            successMessage = nil
            return
        }
        let cleanProductID = productID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanProductID.isEmpty || (Int(cleanProductID).map { $0 > 0 } ?? false) else {
            errorMessage = "Product ID must be a positive whole number."
            successMessage = nil
            return
        }
        guard !isSubmitting else { return }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        defer { isSubmitting = false }
        do {
            let enquiry = Enquiry(
                name: cleanName,
                email: cleanEmail,
                message: cleanMessage,
                productId: cleanProductID.isEmpty ? nil : Int(cleanProductID)
            )
            let response = try await dataManager.submitEnquiry(enquiry)
            successMessage = "Thanks! Your enquiry #\(response.id) has been sent."
            name = ""
            email = ""
            message = ""
            productID = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
