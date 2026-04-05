import Testing

@testable import Entity

@Suite("FetchState")
struct FetchStateSpec {
    @Test("value returns associated value for success")
    func valueSuccess() {
        let state = FetchState.success("data")
        #expect(state.value == "data")
    }

    @Test("value returns associated value for revealing")
    func valueRevealing() {
        let state = FetchState.revealing("data")
        #expect(state.value == "data")
    }

    @Test("value returns nil for idle, loading, failure")
    func valueNil() {
        #expect(FetchState<String>.idle.value == nil)
        #expect(FetchState<String>.loading.value == nil)
        #expect(FetchState<String>.failure.value == nil)
    }

    @Test("isLoading")
    func isLoading() {
        #expect(FetchState<String>.loading.isLoading)
        #expect(!FetchState<String>.idle.isLoading)
        #expect(!FetchState.success("x").isLoading)
    }

    @Test("isRevealing")
    func isRevealing() {
        #expect(FetchState.revealing("x").isRevealing)
        #expect(!FetchState<String>.idle.isRevealing)
        #expect(!FetchState.success("x").isRevealing)
    }

    @Test("isIdle")
    func isIdle() {
        #expect(FetchState<String>.idle.isIdle)
        #expect(!FetchState<String>.loading.isIdle)
        #expect(!FetchState.success("x").isIdle)
    }

    @Test("isSuccess (via value != nil)")
    func isSuccess() {
        #expect(FetchState.success(42).value != nil)
        #expect(FetchState<Int>.failure.value == nil)
    }
}
