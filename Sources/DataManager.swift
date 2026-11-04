import Foundation

@MainActor
protocol StoreDataManaging {
    func login(username: String, password: String) async throws -> String
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: Int) async throws -> Product
    func fetchCategories() async throws -> [String]
    func fetchProducts(category: String) async throws -> [Product]
    func searchProducts(query: String) async throws -> [Product]
    func submitEnquiry(_ enquiry: Enquiry) async throws -> EnquiryResponse
}

@MainActor
final class StoreDataManager: StoreDataManaging {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = URL(string: "http://localhost:8080/api")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func login(username: String, password: String) async throws -> String {
        let body = try encoder.encode(LoginBody(username: username, password: password))
        let response: LoginResponse = try await request(
            path: "auth/login",
            method: "POST",
            body: body
        )
        return response.token
    }

    func fetchProducts() async throws -> [Product] {
        try await request(path: "products")
    }

    func fetchProduct(id: Int) async throws -> Product {
        try await request(path: "products/\(id)")
    }

    func fetchCategories() async throws -> [String] {
        try await request(path: "categories")
    }

    func fetchProducts(category: String) async throws -> [Product] {
        try await request(path: "products/category/\(category)")
    }

    func searchProducts(query: String) async throws -> [Product] {
        var components = URLComponents(url: baseURL.appending(path: "products/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components?.url else { throw StoreAPIError.invalidURL }
        return try await request(url: url)
    }

    func submitEnquiry(_ enquiry: Enquiry) async throws -> EnquiryResponse {
        let body = try encoder.encode(enquiry)
        return try await request(path: "enquiries", method: "POST", body: body)
    }

    private func request<Response: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Response {
        try await request(url: baseURL.appending(path: path), method: method, body: body)
    }

    private func request<Response: Decodable>(
        url: URL,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw StoreAPIError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoreAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? ""
            throw StoreAPIError.server(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw StoreAPIError.decoding
        }
    }
}

private struct LoginBody: Encodable {
    let username: String
    let password: String
}
