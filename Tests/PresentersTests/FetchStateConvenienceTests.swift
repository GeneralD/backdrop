import Domain
import Testing

@testable import Presenters

@Suite("FetchState+Convenience")
struct FetchStateConvenienceTests {

    // MARK: - value

    @Suite("value")
    struct Value {
        @Test("returns value from .success")
        func successValue() {
            let state: FetchState<String> = .success("hello")
            #expect(state.value == "hello")
        }

        @Test("returns value from .revealing")
        func revealingValue() {
            let state: FetchState<String> = .revealing("world")
            #expect(state.value == "world")
        }

        @Test("returns nil for .idle")
        func idleValue() {
            let state: FetchState<String> = .idle
            #expect(state.value == nil)
        }

        @Test("returns nil for .loading")
        func loadingValue() {
            let state: FetchState<String> = .loading
            #expect(state.value == nil)
        }

        @Test("returns nil for .failure")
        func failureValue() {
            let state: FetchState<String> = .failure
            #expect(state.value == nil)
        }
    }

    // MARK: - isLoading

    @Suite("isLoading")
    struct IsLoading {
        @Test("true for .loading")
        func trueForLoading() {
            let state: FetchState<String> = .loading
            #expect(state.isLoading)
        }

        @Test("false for non-loading states", arguments: nonLoadingStates)
        func falseForOthers(state: FetchState<String>) {
            #expect(!state.isLoading)
        }

        private static let nonLoadingStates: [FetchState<String>] = [
            .idle, .revealing("x"), .success("x"), .failure,
        ]
    }

    // MARK: - isRevealing

    @Suite("isRevealing")
    struct IsRevealing {
        @Test("true for .revealing")
        func trueForRevealing() {
            let state: FetchState<String> = .revealing("data")
            #expect(state.isRevealing)
        }

        @Test("false for non-revealing states", arguments: nonRevealingStates)
        func falseForOthers(state: FetchState<String>) {
            #expect(!state.isRevealing)
        }

        private static let nonRevealingStates: [FetchState<String>] = [
            .idle, .loading, .success("x"), .failure,
        ]
    }

    // MARK: - isIdle

    @Suite("isIdle")
    struct IsIdle {
        @Test("true for .idle")
        func trueForIdle() {
            let state: FetchState<String> = .idle
            #expect(state.isIdle)
        }

        @Test("false for non-idle states", arguments: nonIdleStates)
        func falseForOthers(state: FetchState<String>) {
            #expect(!state.isIdle)
        }

        private static let nonIdleStates: [FetchState<String>] = [
            .loading, .revealing("x"), .success("x"), .failure,
        ]
    }

    // MARK: - isSuccess

    @Suite("isSuccess")
    struct IsSuccess {
        @Test("true for .success")
        func trueForSuccess() {
            let state: FetchState<String> = .success("done")
            #expect(state.isSuccess)
        }

        @Test("false for non-success states", arguments: nonSuccessStates)
        func falseForOthers(state: FetchState<String>) {
            #expect(!state.isSuccess)
        }

        private static let nonSuccessStates: [FetchState<String>] = [
            .idle, .loading, .revealing("x"), .failure,
        ]
    }
}
