import SwiftUI

private enum StorePalette {
    static let ink = Color(red: 0.13, green: 0.17, blue: 0.24)
    static let muted = Color(red: 0.48, green: 0.51, blue: 0.56)
    static let canvas = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let card = Color.white
    static let coral = Color(red: 0.96, green: 0.40, blue: 0.29)
    static let gold = Color(red: 0.98, green: 0.72, blue: 0.25)
    static let mint = Color(red: 0.76, green: 0.89, blue: 0.81)
    static let lilac = Color(red: 0.86, green: 0.82, blue: 0.95)
    static let line = Color(red: 0.90, green: 0.89, blue: 0.87)
}

private enum StoreTab: Hashable {
    case products
    case categories
    case search
    case enquiry
}

struct StoreTabView: View {
    let dataManager: any StoreDataManaging
    let onSignOut: () -> Void
    @State private var selection: StoreTab = .products

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                ProductListScreen(dataManager: dataManager, onSignOut: onSignOut)
            }
            .tabItem { Label("Discover", systemImage: "sparkles.rectangle.stack.fill") }
            .tag(StoreTab.products)

            NavigationStack {
                CategoryScreen(dataManager: dataManager)
            }
            .tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }
            .tag(StoreTab.categories)

            NavigationStack {
                SearchScreen(dataManager: dataManager)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(StoreTab.search)

            NavigationStack {
                EnquiryScreen(dataManager: dataManager)
            }
            .tabItem { Label("Enquiry", systemImage: "bubble.left.and.bubble.right.fill") }
            .tag(StoreTab.enquiry)
        }
        .tint(StorePalette.ink)
    }
}

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    init(dataManager: any StoreDataManaging, onLogin: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(dataManager: dataManager, onLogin: onLogin))
    }

    var body: some View {
        ZStack {
            StorePalette.canvas.ignoresSafeArea()
            Circle()
                .fill(StorePalette.mint.opacity(0.75))
                .frame(width: 260, height: 260)
                .blur(radius: 3)
                .offset(x: 170, y: -340)
            Circle()
                .fill(StorePalette.lilac.opacity(0.85))
                .frame(width: 210, height: 210)
                .blur(radius: 4)
                .offset(x: -170, y: 390)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Spacer(minLength: 48)
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(StorePalette.ink)
                                .frame(width: 72, height: 72)
                            Image(systemName: "bag.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(.white)
                                .overlay(alignment: .topTrailing) {
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(StorePalette.gold)
                                        .offset(x: 9, y: -9)
                                }
                        }
                        Text("A little joy,\nevery day.")
                            .font(.system(size: 43, weight: .bold, design: .rounded))
                            .tracking(-1.5)
                            .foregroundStyle(StorePalette.ink)
                        Text("Meet your new favorite way to shop.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(StorePalette.muted)
                    }
                    .padding(.top, 26)

                    VStack(spacing: 15) {
                        InputField(title: "USERNAME", placeholder: "Your Fake Store username", icon: "person", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(StorePalette.muted)
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundStyle(StorePalette.muted)
                                    .frame(width: 20)
                                SecureField("Your password", text: $viewModel.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit { Task { await viewModel.signIn() } }
                            }
                            .padding(17)
                            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 17).stroke(StorePalette.line, lineWidth: 1))
                        }
                    }

                    if let error = viewModel.errorMessage {
                        MessageBanner(text: error, isSuccess: false)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Button {
                        Task { await viewModel.signIn() }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Let’s get started")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 19)
                        .background(StorePalette.coral.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: StorePalette.coral.opacity(0.28), radius: 16, x: 0, y: 9)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(viewModel.isLoading)

                    HStack(spacing: 7) {
                        Image(systemName: "lock.shield")
                        Text("Secure sign in powered by Fake Store")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(StorePalette.muted)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 27)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct InputField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(StorePalette.muted)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(StorePalette.muted)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
            }
            .padding(17)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(StorePalette.line, lineWidth: 1))
        }
    }
}

struct ProductListScreen: View {
    @StateObject private var viewModel: ProductListViewModel
    private let dataManager: any StoreDataManaging
    let onSignOut: () -> Void

    init(dataManager: any StoreDataManaging, onSignOut: @escaping () -> Void = {}) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: ProductListViewModel(dataManager: dataManager))
        self.onSignOut = onSignOut
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("THE GOOD FINDS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(StorePalette.coral)
                        Text("Discover")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .tracking(-0.7)
                            .foregroundStyle(StorePalette.ink)
                    }
                    Spacer()
                    Button(action: onSignOut) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(StorePalette.ink)
                            .frame(width: 46, height: 46)
                            .background(.white, in: Circle())
                    }
                    .accessibilityLabel("Sign out")
                }
                .padding(.top, 10)

                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find your\nnext favorite.")
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(StorePalette.ink)
                        Text("Little things. Big smiles.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(StorePalette.ink.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 47, weight: .medium))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(StorePalette.coral, StorePalette.gold)
                        .rotationEffect(.degrees(-9))
                        .accessibilityHidden(true)
                }
                .padding(22)
                .background(
                    LinearGradient(colors: [StorePalette.mint, Color(red: 0.90, green: 0.94, blue: 0.84)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 25, style: .continuous)
                )

                HStack(alignment: .firstTextBaseline) {
                    Text("Picked for you")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(StorePalette.ink)
                    Spacer()
                    Text("\(viewModel.products.count) FINDS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(StorePalette.muted)
                }

                ProductCollection(products: viewModel.products, isLoading: viewModel.isLoading, errorMessage: viewModel.errorMessage, dataManager: dataManager) {
                    Task { await viewModel.load() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct ProductCollection: View {
    let products: [Product]
    let isLoading: Bool
    let errorMessage: String?
    let dataManager: any StoreDataManaging
    let retry: () -> Void

    var body: some View {
        if isLoading && products.isEmpty {
            LoadingState()
        } else if let errorMessage, products.isEmpty {
            ErrorState(message: errorMessage, retry: retry)
        } else if products.isEmpty {
            EmptyState(icon: "bag", title: "Nothing here yet", subtitle: "Check back soon for fresh finds.")
        } else {
            LazyVStack(spacing: 14) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    NavigationLink(value: product) {
                        ProductCard(product: product)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .opacity(isLoading ? 0.65 : 1)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.42, dampingFraction: 0.82).delay(Double(min(index, 6)) * 0.035), value: products)
                }
            }
            .navigationDestination(for: Product.self) { product in
                ProductDetailScreen(productID: product.id, dataManager: dataManager)
            }
        }
    }
}

struct ProductCard: View {
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            ProductImage(url: product.image, cornerRadius: 17)
                .frame(width: 110, height: 110)
                .background(StorePalette.canvas, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 7) {
                Text(product.categoryTitle.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(StorePalette.coral)
                Text(product.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(StorePalette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(StorePalette.gold)
                    Text(product.rating?.rate.formatted(.number.precision(.fractionLength(1))) ?? "New")
                        .foregroundStyle(StorePalette.muted)
                    if let count = product.rating?.count {
                        Text("· \(count)")
                            .foregroundStyle(StorePalette.muted)
                    }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                Spacer(minLength: 0)
                Text(product.formattedPrice)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(StorePalette.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(StorePalette.muted)
                .frame(width: 30, height: 30)
                .background(StorePalette.canvas, in: Circle())
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(13)
        .background(StorePalette.card, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(StorePalette.line.opacity(0.6), lineWidth: 1))
        .shadow(color: StorePalette.ink.opacity(0.035), radius: 14, x: 0, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
    }
}

struct ProductImage: View {
    let url: URL
    var cornerRadius: CGFloat = 22

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit().padding(11)
                    .transition(.opacity)
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 26))
                    .foregroundStyle(StorePalette.muted.opacity(0.6))
            case .empty:
                ProgressView().tint(StorePalette.coral)
            @unknown default:
                Image(systemName: "bag")
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ProductDetailScreen: View {
    @StateObject private var viewModel: ProductDetailViewModel

    init(productID: Int, dataManager: any StoreDataManaging) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productID: productID, dataManager: dataManager))
    }

    var body: some View {
        ScrollView {
            Group {
                if viewModel.isLoading && viewModel.product == nil {
                    LoadingState().frame(height: 400)
                } else if let error = viewModel.errorMessage, viewModel.product == nil {
                    ErrorState(message: error) { Task { await viewModel.load() } }
                        .frame(height: 400)
                } else if let product = viewModel.product {
                    detail(product)
                }
            }
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .navigationTitle("The details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private func detail(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            ProductImage(url: product.image, cornerRadius: 30)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: StorePalette.ink.opacity(0.05), radius: 18, x: 0, y: 8)
                .padding(.top, 12)

            Text(product.categoryTitle.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(StorePalette.coral)
            Text(product.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.5)
                .foregroundStyle(StorePalette.ink)
            HStack {
                Text(product.formattedPrice)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(StorePalette.ink)
                Spacer()
                if let rating = product.rating {
                    Label("\(rating.rate, format: .number.precision(.fractionLength(1)))  ·  \(rating.count) reviews", systemImage: "star.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(StorePalette.gold)
                }
            }
            VStack(alignment: .leading, spacing: 9) {
                Text("A little more about it")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(StorePalette.ink)
                Text(product.description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .lineSpacing(5)
                    .foregroundStyle(StorePalette.muted)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

struct CategoryScreen: View {
    @StateObject private var viewModel: CategoryViewModel
    private let dataManager: any StoreDataManaging
    private let categoryStyles: [(String, String, Color)] = [
        ("electronics", "desktopcomputer", StorePalette.lilac),
        ("jewelery", "sparkles", StorePalette.gold.opacity(0.28)),
        ("men's clothing", "tshirt", StorePalette.mint),
        ("women's clothing", "handbag", Color(red: 0.98, green: 0.83, blue: 0.80))
    ]

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: CategoryViewModel(dataManager: dataManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("A world of little wonders")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.7)
                        .foregroundStyle(StorePalette.ink)
                    Text("Pick a mood. Find a new favorite.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(StorePalette.muted)
                }
                .padding(.top, 12)

                if viewModel.isLoading && viewModel.categories.isEmpty {
                    LoadingState()
                } else if let error = viewModel.errorMessage, viewModel.categories.isEmpty {
                    ErrorState(message: error) { Task { await viewModel.load() } }
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(viewModel.categories.enumerated()), id: \.element) { index, category in
                            let style = style(for: category, at: index)
                            NavigationLink {
                                CategoryProductsScreen(category: category, dataManager: dataManager)
                            } label: {
                                HStack(spacing: 18) {
                                    Image(systemName: style.1)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundStyle(StorePalette.ink)
                                        .frame(width: 62, height: 62)
                                        .background(style.2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(category.capitalized)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundStyle(StorePalette.ink)
                                        Text("Explore the collection")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(StorePalette.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(StorePalette.ink)
                                        .frame(width: 34, height: 34)
                                        .background(StorePalette.canvas, in: Circle())
                                }
                                .padding(15)
                                .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(StorePalette.line.opacity(0.65), lineWidth: 1))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private func style(for category: String, at index: Int) -> (String, String, Color) {
        categoryStyles.first { $0.0.lowercased() == category.lowercased() }
            .map { ($0.0, $0.1, $0.2) }
            ?? (category, "square.grid.2x2", [StorePalette.mint, StorePalette.lilac, StorePalette.gold.opacity(0.28)][index % 3])
    }
}

private struct CategoryProductsScreen: View {
    let category: String
    private let dataManager: any StoreDataManaging
    @StateObject private var viewModel: ProductListViewModel

    init(category: String, dataManager: any StoreDataManaging) {
        self.category = category
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: ProductListViewModel(dataManager: dataManager))
    }

    var body: some View {
        ScrollView {
            ProductCollection(products: viewModel.products, isLoading: viewModel.isLoading, errorMessage: viewModel.errorMessage, dataManager: dataManager) {
                Task { await viewModel.load(category: category) }
            }
            .padding(20)
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .navigationTitle(category.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(category: category) }
    }
}

struct SearchScreen: View {
    @StateObject private var viewModel: SearchViewModel
    @FocusState private var searchFocused: Bool
    private let dataManager: any StoreDataManaging

    init(dataManager: any StoreDataManaging) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: SearchViewModel(dataManager: dataManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("What are you\nlooking for?")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(StorePalette.ink)
                    Text("A little search can spark a big find.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(StorePalette.muted)
                }
                .padding(.top, 12)

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(StorePalette.coral)
                    TextField("Try “backpack” or “jewelry”", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await viewModel.search() } }
                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                            Task { await viewModel.search() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(StorePalette.muted)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(17)
                .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(StorePalette.line, lineWidth: 1))

                if let error = viewModel.errorMessage {
                    ErrorState(message: error) { Task { await viewModel.search() } }
                } else if viewModel.isLoading {
                    LoadingState()
                } else if !viewModel.query.isEmpty && viewModel.products.isEmpty {
                    EmptyState(icon: "magnifyingglass", title: "No matches just yet", subtitle: "Try a different word and see what you find.")
                } else if viewModel.products.isEmpty {
                    EmptyState(icon: "sparkle.magnifyingglass", title: "Your next favorite is out there", subtitle: "Search the collection to find it.")
                } else {
                    ProductCollection(products: viewModel.products, isLoading: false, errorMessage: nil, dataManager: dataManager) {}
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.22), value: viewModel.products)
    }
}

struct EnquiryScreen: View {
    @StateObject private var viewModel: EnquiryViewModel

    init(dataManager: any StoreDataManaging) {
        _viewModel = StateObject(wrappedValue: EnquiryViewModel(dataManager: dataManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(StorePalette.coral)
                        .frame(width: 58, height: 58)
                        .background(StorePalette.gold.opacity(0.25), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                    Text("We’re all ears.")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .tracking(-0.7)
                        .foregroundStyle(StorePalette.ink)
                    Text("Questions, ideas, or just a hello? Send us a note.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(StorePalette.muted)
                }
                .padding(.top, 12)

                VStack(spacing: 15) {
                    FormField(title: "YOUR NAME", placeholder: "How should we call you?", text: $viewModel.name)
                        .textContentType(.name)
                    FormField(title: "EMAIL ADDRESS", placeholder: "you@example.com", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                    FormField(title: "PRODUCT ID (OPTIONAL)", placeholder: "Add an item you’re asking about", text: $viewModel.productID)
                        .keyboardType(.numberPad)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR MESSAGE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(StorePalette.muted)
                        TextField("Tell us a little more…", text: $viewModel.message, axis: .vertical)
                            .lineLimit(5...8)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 17).stroke(StorePalette.line, lineWidth: 1))
                    }
                }

                if let error = viewModel.errorMessage {
                    MessageBanner(text: error, isSuccess: false)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                if let success = viewModel.successMessage {
                    MessageBanner(text: success, isSuccess: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send my note")
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(StorePalette.ink.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(viewModel.isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(StorePalette.canvas.ignoresSafeArea())
        .navigationTitle("Say hello")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(StorePalette.muted)
            TextField(placeholder, text: $text)
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(StorePalette.line, lineWidth: 1))
        }
    }
}

private struct MessageBanner: View {
    let text: String
    let isSuccess: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(isSuccess ? Color(red: 0.15, green: 0.48, blue: 0.32) : StorePalette.coral)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSuccess ? StorePalette.mint.opacity(0.55) : StorePalette.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct LoadingState: View {
    var body: some View {
        VStack(spacing: 13) {
            ProgressView().tint(StorePalette.coral).scaleEffect(1.1)
            Text("Finding the good stuff…")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(StorePalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 55)
    }
}

private struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 25))
                .foregroundStyle(StorePalette.coral)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(StorePalette.muted)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(StorePalette.coral)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(StorePalette.coral)
                .frame(width: 62, height: 62)
                .background(StorePalette.coral.opacity(0.10), in: Circle())
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(StorePalette.ink)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(StorePalette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}
