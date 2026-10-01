import Foundation

struct CoolSpotsAPILoader {
    enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidResponse
    }

    private let url: URL
    private let session: URLSession

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func load() async throws -> CoolSpotsAPIResponse {
        try Task.checkCancellation()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let received: (data: Data, response: URLResponse)

        do {
            received = try await session.data(for: request)
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw Error.connectivity
        }

        try Task.checkCancellation()

        guard let response = received.response as? HTTPURLResponse,
              response.statusCode == 200 else {
            throw Error.invalidResponse
        }

        do {
            return try CoolSpotsAPIResponse.decode(received.data)
        } catch {
            throw Error.invalidResponse
        }
    }
}
