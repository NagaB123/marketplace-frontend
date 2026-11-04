import Foundation
import XCTest
@testable import FakeStoreFrontend

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    private static let lock = NSLock()

    static func setHandler(_ newHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?) {
        lock.lock()
        defer { lock.unlock() }
        handler = newHandler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let currentHandler = Self.handler
        Self.lock.unlock()

        guard let currentHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try currentHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@MainActor
final class DataManagerTests: XCTestCase {
    private let baseURL = URL(string: "https://example.test/api")!

    private func makeManager() -> StoreDataManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return StoreDataManager(baseURL: baseURL, session: URLSession(configuration: configuration))
    }

    private func response(for request: URLRequest, status: Int = 200, json: String) -> (HTTPURLResponse, Data) {
        (
            HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
            Data(json.utf8)
        )
    }

    func testFetchProductsDecodesProductList() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.url?.path, "/api/products")
            return response(for: request, json: Self.productsJSON)
        }

        let products = try await makeManager().fetchProducts()

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.title, "Everyday Backpack")
        XCTAssertEqual(products.first?.formattedPrice, "$19.99")
    }

    func testFetchProductDetailsUsesProductID() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.url?.path, "/api/products/12")
            return response(for: request, json: Self.productJSON)
        }

        let product = try await makeManager().fetchProduct(id: 12)

        XCTAssertEqual(product.id, 12)
        XCTAssertEqual(product.title, "Everyday Backpack")
    }

    func testFetchCategoriesDecodesCategoryNames() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.url?.path, "/api/categories")
            return response(for: request, json: #"["electronics","jewelery"]"#)
        }

        let categories = try await makeManager().fetchCategories()

        XCTAssertEqual(categories, ["electronics", "jewelery"])
    }

    func testSearchEncodesQueryAndDecodesResults() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.url?.path, "/api/products/search")
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "red shirt")
            return response(for: request, json: Self.productsJSON)
        }

        let products = try await makeManager().searchProducts(query: "red shirt")

        XCTAssertEqual(products.map(\.id), [1])
    }

    func testCategoryEncodesSpacesAsSinglePathSegment() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.percentEncodedPath, "/api/products/category/men's%20clothing")
            return response(for: request, json: Self.productsJSON)
        }

        let products = try await makeManager().fetchProducts(category: "men's clothing")

        XCTAssertEqual(products.count, 1)
    }

    func testLoginPostsCredentials() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/auth/login")
            let body = try requestBody(for: request)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
            XCTAssertEqual(json["username"], "shopper")
            XCTAssertEqual(json["password"], "secret")
            return response(for: request, json: #"{"token":"session-token"}"#)
        }

        let token = try await makeManager().login(username: "shopper", password: "secret")

        XCTAssertEqual(token, "session-token")
    }

    func testSubmitEnquiryPostsFormAndDecodesConfirmation() async throws {
        MockURLProtocol.setHandler { [self] request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/enquiries")
            let body = try requestBody(for: request)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["name"] as? String, "Shopper")
            XCTAssertEqual(json["email"] as? String, "shopper@example.com")
            XCTAssertEqual(json["productId"] as? Int, 7)
            return response(for: request, status: 201, json: #"{"id":42,"status":"submitted"}"#)
        }

        let result = try await makeManager().submitEnquiry(
            Enquiry(name: "Shopper", email: "shopper@example.com", message: "A question", productId: 7)
        )

        XCTAssertEqual(result.id, 42)
        XCTAssertEqual(result.status, "submitted")
    }

    func testNonSuccessResponsePreservesHTTPStatus() async {
        MockURLProtocol.setHandler { [self] request in
            response(for: request, status: 401, json: #"{"error":"Invalid credentials"}"#)
        }

        do {
            _ = try await makeManager().fetchProducts()
            XCTFail("Expected an authorization error")
        } catch let error as StoreAPIError {
            guard case let .server(statusCode, message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "Invalid credentials")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMalformedResponseProducesDecodingError() async {
        MockURLProtocol.setHandler { [self] request in
            response(for: request, json: #"{"not":"a product list"}"#)
        }

        do {
            _ = try await makeManager().fetchProducts()
            XCTFail("Expected a decoding error")
        } catch let error as StoreAPIError {
            guard case .decoding = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private static let productsJSON = """
    [{"id":1,"title":"Everyday Backpack","price":19.99,"description":"A handy bag","category":"men's clothing","image":"https://example.test/bag.png","rating":{"rate":4.5,"count":21}}]
    """

    private static let productJSON = """
    {"id":12,"title":"Everyday Backpack","price":19.99,"description":"A handy bag","category":"men's clothing","image":"https://example.test/bag.png","rating":{"rate":4.5,"count":21}}
    """

    private func requestBody(for request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }
        let stream = try XCTUnwrap(request.httpBodyStream)
        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = buffer.withUnsafeMutableBufferPointer {
                stream.read($0.baseAddress!, maxLength: $0.count)
            }
            if count < 0 {
                throw stream.streamError ?? URLError(.unknown)
            }
            if count == 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

@MainActor
final class ViewModelTests: XCTestCase {
    func testLoginRequiresCredentials() async {
        let dataManager = MockStoreDataManager()
        let viewModel = LoginViewModel(dataManager: dataManager) { _ in }

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "Enter your username and password to continue.")
        XCTAssertEqual(dataManager.loginCallCount, 0)
    }

    func testLoginSuccessReturnsToken() async {
        let dataManager = MockStoreDataManager()
        var receivedToken: String?
        let viewModel = LoginViewModel(dataManager: dataManager) { receivedToken = $0 }
        viewModel.username = "  shopper  "
        viewModel.password = "secret"

        await viewModel.signIn()

        XCTAssertEqual(receivedToken, "test-token")
        XCTAssertEqual(dataManager.lastLoginUsername, "shopper")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testProductListReportsLoadFailure() async {
        let dataManager = MockStoreDataManager()
        dataManager.failure = TestFailure.unavailable
        let viewModel = ProductListViewModel(dataManager: dataManager)

        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, TestFailure.unavailable.localizedDescription)
        XCTAssertTrue(viewModel.products.isEmpty)
    }

    func testSearchDoesNotRequestEmptyQuery() async {
        let dataManager = MockStoreDataManager()
        let viewModel = SearchViewModel(dataManager: dataManager)

        await viewModel.search()

        XCTAssertEqual(dataManager.searchCallCount, 0)
        XCTAssertTrue(viewModel.products.isEmpty)
    }

    func testEnquiryRejectsInvalidEmailAndProductID() async {
        let dataManager = MockStoreDataManager()
        let viewModel = EnquiryViewModel(dataManager: dataManager)
        viewModel.name = "Shopper"
        viewModel.email = "not-an-email"
        viewModel.message = "Please help"

        await viewModel.submit()
        XCTAssertEqual(viewModel.errorMessage, "Enter a valid email address.")
        XCTAssertEqual(dataManager.enquiryCallCount, 0)

        viewModel.email = "shopper@example.com"
        viewModel.productID = "-2"
        await viewModel.submit()
        XCTAssertEqual(viewModel.errorMessage, "Product ID must be a positive whole number.")
        XCTAssertEqual(dataManager.enquiryCallCount, 0)
    }

    func testEnquirySuccessClearsFormAndShowsConfirmation() async {
        let dataManager = MockStoreDataManager()
        let viewModel = EnquiryViewModel(dataManager: dataManager)
        viewModel.name = "Shopper"
        viewModel.email = "shopper@example.com"
        viewModel.message = "I have a question"
        viewModel.productID = "7"

        await viewModel.submit()

        XCTAssertEqual(dataManager.lastEnquiry?.productId, 7)
        XCTAssertEqual(viewModel.successMessage, "Thanks! Your enquiry #42 has been sent.")
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.message.isEmpty)
        XCTAssertTrue(viewModel.productID.isEmpty)
    }
}

@MainActor
private final class MockStoreDataManager: StoreDataManaging {
    var failure: Error?
    var loginCallCount = 0
    var searchCallCount = 0
    var enquiryCallCount = 0
    var lastLoginUsername: String?
    var lastEnquiry: Enquiry?

    func login(username: String, password: String) async throws -> String {
        loginCallCount += 1
        lastLoginUsername = username
        if let failure { throw failure }
        return "test-token"
    }

    func fetchProducts() async throws -> [Product] {
        if let failure { throw failure }
        return []
    }

    func fetchProduct(id: Int) async throws -> Product {
        if let failure { throw failure }
        throw TestFailure.unavailable
    }

    func fetchCategories() async throws -> [String] {
        if let failure { throw failure }
        return []
    }

    func fetchProducts(category: String) async throws -> [Product] {
        if let failure { throw failure }
        return []
    }

    func searchProducts(query: String) async throws -> [Product] {
        searchCallCount += 1
        if let failure { throw failure }
        return []
    }

    func submitEnquiry(_ enquiry: Enquiry) async throws -> EnquiryResponse {
        enquiryCallCount += 1
        lastEnquiry = enquiry
        if let failure { throw failure }
        return EnquiryResponse(id: 42, status: "submitted")
    }
}

private enum TestFailure: LocalizedError {
    case unavailable

    var errorDescription: String? { "The service is temporarily unavailable." }
}
