import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: URL
    let rating: ProductRating?

    var formattedPrice: String {
        price.formatted(.currency(code: "USD"))
    }

    var categoryTitle: String {
        category.capitalized
    }
}

struct ProductRating: Codable, Hashable {
    let rate: Double
    let count: Int
}

struct LoginResponse: Decodable {
    let token: String
}

struct Enquiry: Encodable {
    let name: String
    let email: String
    let message: String
    let productId: Int?
}

struct EnquiryResponse: Decodable {
    let id: Int
    let status: String
}

enum StoreAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String)
    case decoding
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The API address is invalid."
        case .invalidResponse:
            "The server returned an invalid response."
        case let .server(_, message):
            message.isEmpty ? "The request could not be completed." : message
        case .decoding:
            "The server response could not be read."
        case let .network(message):
            message
        }
    }
}
