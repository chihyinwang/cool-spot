import Combine
import Foundation

@MainActor
final class CoolSpotsCatalogueViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded([CoolSpot])
        case failed
    }

    @Published private(set) var state: State = .idle

    private let loadCatalogue:
        @MainActor () async throws -> CoolSpotsAPIResponse

    init(
        load: @escaping @MainActor () async throws -> CoolSpotsAPIResponse
    ) {
        loadCatalogue = load
    }

    func load() async {
        guard !Task.isCancelled else { return }
        if case .loading = state { return }

        state = .loading

        do {
            let response = try await loadCatalogue()
            try Task.checkCancellation()
            state = .loaded(response.makeSpots())
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                state = .failed
            }
        }
    }
}
