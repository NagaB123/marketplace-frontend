# FakeStore Frontend

Native iOS shopping app built with SwiftUI and MVVM. The project is `FakeStoreFrontend.xcodeproj`; it supports iOS 17 and later.

## Run the app

1. Start the backend from `~/Desktop/fakestore-backend` with `npm run dev`.
2. Open `FakeStoreFrontend.xcodeproj` in Xcode.
3. Select an iPhone simulator and run the **FakeStoreFrontend** scheme.
4. Sign in with a Fake Store API account. The app talks to the local backend at `http://localhost:8080/api`.

The simulator can use the Mac's `localhost`. For a physical iPhone, change the base URL in `Sources/DataManager.swift` to the Mac's LAN address, allow local network access, and keep both devices on the same network.

## Architecture

- `Sources/DataManager.swift`: injected API abstraction and URLSession-backed implementation.
- `Sources/ViewModels.swift`: `@MainActor` observable view models with `@Published` UI state.
- `Sources/AppViews.swift`: login, four tab screens, product cards, category browsing, search, enquiry form, and product details.
- `Sources/Models.swift`: API request/response models and user-facing API errors.
- `Tests/FakeStoreFrontendTests.swift`: URLProtocol-backed API tests and mock DataManager view-model tests.

## API routes

- `POST /api/auth/login`
- `GET /api/products`
- `GET /api/products/:id`
- `GET /api/categories`
- `GET /api/products/category/:category`
- `GET /api/products/search?q=...`
- `POST /api/enquiries`

Run unit tests in Xcode with **Product > Test**, or from Terminal:

```sh
xcodebuild test \
  -project FakeStoreFrontend.xcodeproj \
  -scheme FakeStoreFrontend \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
