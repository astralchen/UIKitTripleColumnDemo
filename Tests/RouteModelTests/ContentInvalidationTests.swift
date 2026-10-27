import XCTest
@testable import RouteModel

final class ContentInvalidationTests: XCTestCase {
    private func library() -> ReadingLibrary {
        ReadingLibrary(categoryID: "UIKit", articleID: "文章 A")
    }
    func testDeletedArticleWinsOverBothGestureOutcomes() {
        for cancelled in [false, true] {
            var content = library()
            var route = RouteLedger(route: .detail)
            let back = route.beginNavigation(to: .list)!
            content.deleteArticle("文章 A", in: "UIKit")
            route.contentChanged(correctedRoute: content.correctedRoute(route.route))
            XCTAssertNil(content.articleID)
            XCTAssertEqual(route.route, .list) // 不等动画结束才清除无效详情。
            XCTAssertNotNil(route.pending) // 仍等 UIKit，不能此时强行启动另一笔 show。
            XCTAssertNil(route.takeReconciliation())
            route.finishNavigation(id: back.id, cancelled: cancelled)
            XCTAssertEqual(route.route, .list)
            XCTAssertEqual(route.takeReconciliation(), .list)
        }
    }
    func testDeleteAndLayoutInBothCompletionOrders() {
        for cancelled in [false, true] {
            for layoutFinishesFirst in [false, true] {
                var content = library()
                var route = RouteLedger(route: .detail)
                let back = route.beginNavigation(to: .list)!
                let layout = route.beginLayout()
                content.deleteArticle("文章 A", in: "UIKit")
                route.contentChanged(correctedRoute: content.correctedRoute(route.route))
                if layoutFinishesFirst { route.endLayout(layout) }
                route.finishNavigation(id: back.id, cancelled: cancelled)
                if !layoutFinishesFirst {
                    XCTAssertNil(route.takeReconciliation())
                    route.endLayout(layout)
                }
                XCTAssertEqual(route.takeReconciliation(), .list)
                XCTAssertNil(content.articleID)
            }
        }
    }
    func testCategorySwitchSupersedesOldReturnToCategories() {
        for cancelled in [false, true] {
            var content = library()
            var route = RouteLedger(route: .list)
            let oldBack = route.beginNavigation(to: .categories)!
            XCTAssertTrue(content.selectCategory("Swift"))
            route.contentChanged(correctedRoute: content.correctedRoute(.list))
            route.finishNavigation(id: oldBack.id, cancelled: cancelled)
            XCTAssertEqual(content.categoryID, "Swift")
            XCTAssertNil(content.articleID)
            XCTAssertEqual(route.takeReconciliation(), .list) // 旧成功结果 categories 也不能覆盖新意图。
        }
    }
    func testDeletedCategoryFallsBackToCategories() {
        var content = library()
        var route = RouteLedger(route: .detail)
        let back = route.beginNavigation(to: .list)!
        content.deleteCategory("UIKit")
        route.contentChanged(correctedRoute: content.correctedRoute(route.route))
        route.finishNavigation(id: back.id, cancelled: true)
        XCTAssertNil(content.categoryID)
        XCTAssertNil(content.articleID)
        XCTAssertEqual(route.takeReconciliation(), .categories)
    }
    func testUnrelatedDeletionDoesNotInvalidateNavigation() {
        var content = library()
        var route = RouteLedger(route: .detail)
        let back = route.beginNavigation(to: .list)!
        content.deleteArticle("文章 B", in: "UIKit")
        // 当前选择未变，不调用 contentChanged，行为与 UIKit 适配层 updateCatalog 相同。
        XCTAssertEqual(content.articleID, "文章 A")
        route.finishNavigation(id: back.id, cancelled: false)
        XCTAssertEqual(route.route, .list)
        XCTAssertNil(route.takeReconciliation())
    }
    func testStaleAppearanceRejectedEvenAfterRecovery() {
        var route = RouteLedger(route: .detail)
        let oldLayout = route.layoutVersion, oldContent = route.contentVersion
        route.contentChanged(correctedRoute: .list)
        XCTAssertEqual(route.takeReconciliation(), .list)
        XCTAssertFalse(route.confirmStableRoute(.detail, version: oldLayout, contentVersion: oldContent))
        XCTAssertEqual(route.route, .list)
    }
    func testRecreatedIDDoesNotRestoreDeletedSelection() {
        var content = library()
        var route = RouteLedger(route: .detail)
        let back = route.beginNavigation(to: .list)!
        content.deleteArticle("文章 A", in: "UIKit")
        route.contentChanged(correctedRoute: content.correctedRoute(route.route))
        content.replaceCatalog(ReadingLibrary.demoCatalog)
        route.finishNavigation(id: back.id, cancelled: true)
        XCTAssertNil(content.articleID)
        XCTAssertEqual(route.takeReconciliation(), .list)
    }
    func testSecondInvalidationDuringRestorationWins() {
        var content = library()
        var route = RouteLedger(route: .detail)
        content.deleteArticle("文章 A", in: "UIKit")
        route.contentChanged(correctedRoute: content.correctedRoute(route.route))
        XCTAssertEqual(route.takeReconciliation(), .list)
        let restoringList = route.beginLayout()
        content.deleteCategory("UIKit")
        route.contentChanged(correctedRoute: content.correctedRoute(route.route))
        XCTAssertNil(route.takeReconciliation())
        route.endLayout(restoringList)
        XCTAssertEqual(route.takeReconciliation(), .categories)
    }
    func testInitialSnapshotMembershipAndNoForcedNavigationFromCategories() {
        let wrong = ReadingLibrary(categoryID: "Swift", articleID: "文章 A")
        XCTAssertNil(wrong.articleID)
        XCTAssertEqual(wrong.correctedRoute(.detail), .list)
        let missing = ReadingLibrary(categoryID: "已删除分类", articleID: "文章 A")
        XCTAssertEqual(missing.correctedRoute(.detail), .categories)
        var content = library()
        content.deleteArticle("文章 A", in: "UIKit")
        XCTAssertEqual(content.correctedRoute(.categories), .categories)
    }
}
