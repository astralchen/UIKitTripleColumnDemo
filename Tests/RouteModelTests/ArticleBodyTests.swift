import XCTest
@testable import RouteModel

// 故意不响应 Task.cancel()，用 continuation 精确控制返回顺序，不用 sleep 猜时序。
actor ControlledBodyLoader: ArticleBodyLoading {
    private var pending: [UUID: CheckedContinuation<String, Error>] = [:]
    private var arrivals: [ArticleBodyRequest] = []
    private var waiter: CheckedContinuation<ArticleBodyRequest, Never>?
    func load(_ request: ArticleBodyRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            pending[request.id] = continuation
            if let waiter { self.waiter = nil; waiter.resume(returning: request) }
            else { arrivals.append(request) }
        }
    }
    func nextRequest() async -> ArticleBodyRequest {
        if !arrivals.isEmpty { return arrivals.removeFirst() }
        return await withCheckedContinuation { waiter = $0 }
    }
    func finish(_ request: ArticleBodyRequest, _ result: Result<String, Error>) {
        pending.removeValue(forKey: request.id)!.resume(with: result)
    }
}

final class ArticleBodyTests: XCTestCase {
    private func context(_ article: String = "A", version: Int = 1,
                         category: String = "UIKit") -> ArticleBodyContext {
        ArticleBodyContext(categoryID: category, articleID: article, contentVersion: version)
    }
    @MainActor
    private func deliver(_ request: ArticleBodyRequest, _ result: Result<String, Error>,
                         accepted: Bool, loader: ControlledBodyLoader,
                         body: ArticleBodyCoordinator) async {
        let done = expectation(description: "响应已处理")
        body.onResponseProcessed = { actual, didAccept in
            XCTAssertEqual(actual, request); XCTAssertEqual(didAccept, accepted); done.fulfill()
        }
        await loader.finish(request, result)
        await fulfillment(of: [done], timeout: 3)
        body.onResponseProcessed = nil
    }
    @MainActor
    func testBFinishesBeforeA() async {
        let loader = ControlledBodyLoader()
        let state = ArticleBodyCoordinator(loader: loader)
        state.synchronize(context: context()); let a = await loader.nextRequest()
        state.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
        XCTAssertEqual(state.state, .loading(b)) // A 正文立即清除。
        await deliver(b, .success("B 新正文"), accepted: true, loader: loader, body: state)
        await deliver(a, .success("A 旧正文"), accepted: false, loader: loader, body: state)
        XCTAssertEqual(state.state, .loaded(b, "B 新正文"))
    }
    @MainActor
    func testOldFailureAndCancellationCannotClearNewLoading() async {
        for error in [NSError(domain: "测试", code: 500), CancellationError()] as [Error] {
            let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
            body.synchronize(context: context()); let a = await loader.nextRequest()
            body.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
            await deliver(a, .failure(error), accepted: false, loader: loader, body: body)
            XCTAssertEqual(body.state, .loading(b)); XCTAssertEqual(body.activeRequest, b)
            await deliver(b, .success("B"), accepted: true, loader: loader, body: body)
        }
    }
    @MainActor
    func testSameArticleReloadUsesNewRequestIDWithoutVersionChange() async {
        let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
        body.synchronize(context: context()); let first = await loader.nextRequest()
        body.reload(); let second = await loader.nextRequest()
        XCTAssertEqual(first.context, second.context); XCTAssertNotEqual(first.id, second.id)
        await deliver(second, .success("刷新后的正文"), accepted: true, loader: loader, body: body)
        await deliver(first, .success("刷新前的正文"), accepted: false, loader: loader, body: body)
        XCTAssertEqual(body.state, .loaded(second, "刷新后的正文"))
    }
    @MainActor
    func testAToBToADoesNotReviveFirstA() async {
        let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
        body.synchronize(context: context()); let a1 = await loader.nextRequest()
        body.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
        body.synchronize(context: context(version: 3)); let a2 = await loader.nextRequest()
        await deliver(a1, .success("A 旧正文"), accepted: false, loader: loader, body: body)
        await deliver(b, .success("B"), accepted: false, loader: loader, body: body)
        XCTAssertEqual(body.state, .loading(a2))
        await deliver(a2, .success("A 新正文"), accepted: true, loader: loader, body: body)
    }
    @MainActor
    func testDeletionDuringGestureAndLayoutWinsForBothOutcomes() async {
        for cancelled in [false, true] {
            let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
            var library = ReadingLibrary(categoryID: "UIKit", articleID: "文章 A")
            var route = RouteLedger(route: .detail)
            body.synchronize(context: context("文章 A", version: route.contentVersion))
            let request = await loader.nextRequest()
            let back = route.beginNavigation(to: .list)!, layout = route.beginLayout()
            library.deleteArticle("文章 A", in: "UIKit")
            route.contentChanged(correctedRoute: library.correctedRoute(route.route))
            body.synchronize(context: nil) // 立即失效，不等动画。
            await deliver(request, .success("被删除的正文"), accepted: false, loader: loader, body: body)
            route.endLayout(layout); route.finishNavigation(id: back.id, cancelled: cancelled)
            XCTAssertEqual(body.state, .idle); XCTAssertNil(library.articleID)
            XCTAssertEqual(route.takeReconciliation(), .list)
        }
    }
    @MainActor
    func testCategorySwitchAndReusedArticleID() async {
        let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
        body.synchronize(context: context()); let old = await loader.nextRequest()
        body.synchronize(context: nil)
        body.synchronize(context: context(version: 3, category: "Swift"))
        let current = await loader.nextRequest()
        await deliver(old, .success("UIKit A"), accepted: false, loader: loader, body: body)
        XCTAssertEqual(body.state, .loading(current))
        await deliver(current, .success("Swift A"), accepted: true, loader: loader, body: body)
    }
    @MainActor
    func testBackAndLayoutKeepRequestButDoNotRestoreDetail() async {
        let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
        var route = RouteLedger(route: .detail)
        body.synchronize(context: context()); let request = await loader.nextRequest()
        let back = route.beginNavigation(to: .list)!, layout = route.beginLayout()
        route.finishNavigation(id: back.id, cancelled: false); route.endLayout(layout)
        body.synchronize(context: context())
        XCTAssertEqual(body.activeRequest, request) // 相同上下文不产生重复请求。
        await deliver(request, .success("A"), accepted: true, loader: loader, body: body)
        XCTAssertEqual(route.route, .list)
        XCTAssertEqual(body.state, .loaded(request, "A"))
    }
    @MainActor
    func testCurrentFailureCanRetryAndCurrentCancellationEndsLoading() async {
        let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
        body.synchronize(context: context()); let first = await loader.nextRequest()
        let error = NSError(domain: "测试", code: 500)
        await deliver(first, .failure(error), accepted: true, loader: loader, body: body)
        XCTAssertEqual(body.state, .failed(first, error.localizedDescription))
        body.reload(); let second = await loader.nextRequest()
        await deliver(second, .failure(CancellationError()), accepted: true, loader: loader, body: body)
        XCTAssertEqual(body.state, .idle); XCTAssertNil(body.activeRequest)
        body.reload(); let third = await loader.nextRequest()
        await deliver(third, .success("重试成功"), accepted: true, loader: loader, body: body)
    }
}
