import XCTest
@testable import RouteModel

final class RouteLedgerTests: XCTestCase {
    func testCompleteAfterExpansionUsesTarget() {
        var m = RouteLedger(route: .detail)
        let n = m.beginNavigation(to: .list)!
        let layout = m.beginLayout()
        m.endLayout(layout)
        XCTAssertEqual(m.route, .detail)
        XCTAssertNil(m.takeReconciliation()) // 布局结束，但结果尚未确定。
        XCTAssertTrue(m.finishNavigation(id: n.id, cancelled: false))
        XCTAssertEqual(m.route, .list)
        XCTAssertEqual(m.takeReconciliation(), .list)
        XCTAssertNil(m.takeReconciliation())
    }
    func testCancelAfterExpansionKeepsSource() {
        var m = RouteLedger(route: .detail)
        let n = m.beginNavigation(to: .list)!
        let layout = m.beginLayout(); m.endLayout(layout)
        m.finishNavigation(id: n.id, cancelled: true)
        XCTAssertEqual(m.route, .detail)
        XCTAssertEqual(m.takeReconciliation(), .detail)
    }
    func testResultBeforeLayoutEndWaitsForBoth() {
        for cancelled in [false, true] {
            var m = RouteLedger(route: .detail)
            let n = m.beginNavigation(to: .list)!
            let layout = m.beginLayout()
            m.finishNavigation(id: n.id, cancelled: cancelled)
            XCTAssertNil(m.takeReconciliation())
            m.endLayout(layout)
            XCTAssertEqual(m.takeReconciliation(), cancelled ? .detail : .list)
        }
    }
    func testExpandThenCollapseBeforeResult() {
        for cancelled in [false, true] {
            var m = RouteLedger(route: .detail)
            let n = m.beginNavigation(to: .list)!
            let wide = m.beginLayout(); m.endLayout(wide)
            let narrow = m.beginLayout(); m.endLayout(narrow)
            // 折叠决策暂用已提交位置 detail；结果晚到后必须重新校正。
            XCTAssertEqual(m.route, .detail)
            m.finishNavigation(id: n.id, cancelled: cancelled)
            XCTAssertEqual(m.takeReconciliation(), cancelled ? .detail : .list)
        }
    }
    func testNestedSizeAndColumnTransitions() {
        var m = RouteLedger(route: .list)
        let n = m.beginNavigation(to: .categories)!
        let size = m.beginLayout(); let columns = m.beginLayout()
        m.endLayout(columns)
        m.finishNavigation(id: n.id, cancelled: false)
        XCTAssertNil(m.takeReconciliation())
        m.endLayout(size)
        XCTAssertEqual(m.takeReconciliation(), .categories)
        m.endLayout(size) // 重复完成不能破坏布局计数。
        XCTAssertFalse(m.isChangingLayout)
    }
    func testOldCompletionCannotOverwriteNewNavigation() {
        var m = RouteLedger(route: .detail)
        let first = m.beginNavigation(to: .list)!
        m.finishNavigation(id: first.id, cancelled: false)
        let second = m.beginNavigation(to: .categories)!
        XCTAssertFalse(m.finishNavigation(id: first.id, cancelled: true))
        XCTAssertEqual(m.pending?.id, second.id)
        m.finishNavigation(id: second.id, cancelled: false)
        XCTAssertEqual(m.route, .categories)
    }
    func testAppearanceCannotOverwritePendingOrNewLayout() {
        var m = RouteLedger(route: .detail)
        let version = m.layoutVersion
        let n = m.beginNavigation(to: .list)!
        XCTAssertFalse(m.confirmStableRoute(.list, version: version, contentVersion: m.contentVersion))
        let layout = m.beginLayout(); m.endLayout(layout)
        m.finishNavigation(id: n.id, cancelled: true)
        XCTAssertFalse(m.confirmStableRoute(.categories, version: version, contentVersion: m.contentVersion))
        XCTAssertEqual(m.takeReconciliation(), .detail)
        XCTAssertFalse(m.confirmStableRoute(.list, version: version, contentVersion: m.contentVersion))
        XCTAssertEqual(m.route, .detail)
    }
    func testStableNavigationAndWideChoice() {
        var m = RouteLedger(route: .categories)
        XCTAssertTrue(m.confirmStableRoute(.detail, version: m.layoutVersion, contentVersion: m.contentVersion))
        let n = m.beginNavigation(to: .list)!
        XCTAssertNil(m.beginNavigation(to: .categories))
        m.finishNavigation(id: n.id, cancelled: true)
        XCTAssertEqual(m.route, .detail)
        XCTAssertNil(m.takeReconciliation())
    }
}
