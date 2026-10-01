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
    private let didLoad: @MainActor ([CoolSpot]) -> Void

    init(
        load: @escaping @MainActor () async throws -> CoolSpotsAPIResponse,
        didLoad: @escaping @MainActor ([CoolSpot]) -> Void = { _ in }
    ) {
        loadCatalogue = load
        self.didLoad = didLoad
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func requestRetry() -> Bool {
        guard case .failed = state else { return false }
        state = .idle
        return true
    }

    func load() async {
        guard !Task.isCancelled else { return }
        if case .loading = state { return }

        state = .loading

        do {
            let response = try await loadCatalogue()
            try Task.checkCancellation()
            let spots = response.makeSpots()
            didLoad(spots)
            state = .loaded(spots)
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                state = .failed
            }
        }
    }
}
