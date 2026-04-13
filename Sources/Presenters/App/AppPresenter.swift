import Dependencies
import Domain
import Foundation

@MainActor
public final class AppPresenter: ObservableObject {
    @Published public private(set) var layout: ScreenLayout = .init()

    @Dependency(\.screenInteractor) private var screenInteractor
    @Dependency(\.continuousClock) private var clock

    private var vacantTask: Task<Void, Never>?

    public init() {}

    public func start() {
        recalculateLayout()
        startVacantPollingIfNeeded()
    }

    public func stop() {
        vacantTask?.cancel()
        vacantTask = nil
    }

    public func recalculateLayout() {
        layout = screenInteractor.resolveLayout()
    }

    private func startVacantPollingIfNeeded() {
        guard screenInteractor.screenSelector == .vacant else { return }
        let interval = max(screenInteractor.screenDebounce, 1)
        vacantTask = Task { [weak self, clock] in
            while !Task.isCancelled {
                try? await clock.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self?.recalculateLayout()
            }
        }
    }
}
