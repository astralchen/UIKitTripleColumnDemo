import XCTest
import UIKit
final class TripleColumnDemoUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func check(_ app: XCUIApplication, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        XCTAssertTrue(app.staticTexts["route.status"].waitForExistence(timeout: 5),file: file,line: line)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: p, object: app.staticTexts["route.status"])], timeout: 6), .completed,file: file,line: line)
    }
    @MainActor private func launch(_ arguments: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchArguments = arguments; app.launch()
        XCTAssertTrue(app.cells["categories.0"].waitForExistence(timeout: 10))
        app.segmentedControls["route.mode"].buttons["窄屏"].tap()
        check(app,"collapsed=true")
        return app
    }
    @MainActor private func article(_ app: XCUIApplication) {
        app.cells["categories.0"].tap(); check(app,"route=list")
        app.cells["list.0"].tap(); check(app,"route=detail")
    }
    @MainActor func testSystemBackAndWidthRestore() {
        let app = launch(); article(app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        check(app,"route=list article=文章 A")
        app.segmentedControls["route.mode"].buttons["自动"].tap(); check(app,"collapsed=false")
        check(app,"route=list article=文章 A")
        app.segmentedControls["route.mode"].buttons["窄屏"].tap(); check(app,"collapsed=true")
        check(app,"route=list article=文章 A")
        XCTAssertTrue(app.cells["list.0"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap(); check(app,"route=categories article=文章 A")
        app.segmentedControls["route.mode"].buttons["自动"].tap(); check(app,"collapsed=false")
        app.segmentedControls["route.mode"].buttons["窄屏"].tap(); check(app,"route=categories article=文章 A")
        XCTAssertTrue(app.cells["categories.0"].isHittable)
    }
    @MainActor func testInteractiveCancelAndFinish() {
        let app = launch(); article(app)
        let split = app.otherElements["route.split"]
        let edge = split.coordinate(withNormalizedOffset: CGVector(dx:0.005,dy:0.5))
        edge.press(forDuration:0.05, thenDragTo:split.coordinate(withNormalizedOffset:CGVector(dx:0.2,dy:0.5)), withVelocity:.slow, thenHoldForDuration:0.3)
        check(app,"route=detail article=文章 A")
        let p=NSPredicate(format:"label MATCHES %@", ".*cancelled=[1-9][0-9]*.*")
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:p,object:app.staticTexts["route.status"])],timeout:5),.completed)
        edge.press(forDuration:0.05, thenDragTo:split.coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)), withVelocity:.slow, thenHoldForDuration:0.2)
        check(app,"route=list article=文章 A")
        XCTAssertTrue(app.cells["list.0"].isHittable)
    }
    @MainActor private func overlap(_ argument: String, finish: Bool, expected: String?) {
        let app = launch([argument]); article(app)
        let split = app.otherElements["route.split"]
        let start = split.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.5))
        // 手势坐标在宽度改变前计算，拖动使用真实系统边缘返回识别器。
        let end = split.coordinate(withNormalizedOffset: CGVector(dx: finish ? 0.9 : 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        check(app, "collapsed=false")
        check(app, "pending=false layout=false restore=false")
        let label = app.staticTexts["route.status"].label
        XCTAssertTrue(label.range(of: "overlap=[1-9][0-9]*", options: .regularExpression) != nil, label)
        XCTAssertTrue(label.contains("result=completed") || label.contains("result=cancelled"), label)
        if let expected { XCTAssertTrue(label.contains("result=\(expected)"), label) }
        // active 期间 UIKit 可以主动取消；以实际最终结果决定断言，不以拖动距离猜结果。
        let route = label.contains("result=cancelled") ? "detail" : "list"
        check(app, "route=\(route) article=文章 A")
        app.segmentedControls["route.mode"].buttons["窄屏"].tap()
        check(app, "collapsed=true")
        check(app, "route=\(route) article=文章 A")
        XCTAssertTrue(app.cells["\(route).0"].isHittable)
        let attachment = XCTAttachment(string: app.staticTexts["route.status"].label)
        attachment.name = "\(argument)-\(finish)-最终状态"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor func testOverlapDuringActiveGesture() {
        overlap("--overlap-active", finish: true, expected: nil)
    }
    @MainActor func testOverlapAfterFinishDecision() {
        overlap("--overlap-decision", finish: true, expected: "completed")
    }
    @MainActor func testOverlapAfterCancelDecision() {
        overlap("--overlap-decision", finish: false, expected: "cancelled")
    }

    @MainActor private func assertInvalidation(_ app: XCUIApplication, category: String, duringLayout: Bool = false) {
        check(app, "route=list article=nil")
        check(app, "pending=false layout=false restore=false")
        check(app, "category=\(category)")
        let status = app.staticTexts["route.status"].label
        let counter = duringLayout ? "invalidLayout" : "invalidNav"
        XCTAssertNotNil(status.range(of: "\(counter)=[1-9][0-9]*", options: .regularExpression), status)
        if !duringLayout {
            XCTAssertNotNil(status.range(of: "ignoredContent=[1-9][0-9]*", options: .regularExpression), status)
        }
        XCTAssertFalse(app.staticTexts["正文：文章 A"].exists)
    }
    @MainActor private func contentGesture(finish: Bool, switched: Bool = false, expand: Bool = false, active: Bool = false) {
        var args = [switched ? "--content-switch" : "--content-delete"]
        if expand { args.append("--content-expand") }
        if active { args.append("--content-active") }
        let app = launch(args); article(app)
        let split = app.otherElements["route.split"]
        let start = split.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.5))
        let end = split.coordinate(withNormalizedOffset: CGVector(dx: finish ? 0.9 : 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        assertInvalidation(app, category: switched ? "Swift" : "UIKit")
        if !active { check(app, finish ? "result=completed" : "result=cancelled") }
        if expand {
            check(app, "collapsed=false")
            app.segmentedControls["route.mode"].buttons["窄屏"].tap()
            check(app, "collapsed=true")
            assertInvalidation(app, category: switched ? "Swift" : "UIKit")
        }
        XCTAssertTrue(app.cells["list.0"].isHittable)
        XCTAssertTrue(app.staticTexts[switched ? "Swift 文章 C" : "文章 B"].exists)
        XCTAssertFalse(app.staticTexts["文章 A"].exists)
    }
    @MainActor func testDeletionThenCancelledReturnFallsBackToList() {
        contentGesture(finish: false)
    }
    @MainActor func testDeletionThenCompletedReturnAndExpand() {
        contentGesture(finish: true, expand: true)
    }
    @MainActor func testCategorySwitchThenCancelledReturnAndExpand() {
        contentGesture(finish: false, switched: true, expand: true)
    }
    @MainActor func testDeletionDuringActiveGestureAndExpand() {
        contentGesture(finish: true, expand: true, active: true)
    }
    @MainActor func testDeletionDuringColumnExpansion() {
        let app = launch(["--content-layout-delete"]); article(app)
        app.segmentedControls["route.mode"].buttons["自动"].tap()
        check(app, "collapsed=false")
        assertInvalidation(app, category: "UIKit", duringLayout: true)
        app.segmentedControls["route.mode"].buttons["窄屏"].tap()
        check(app, "collapsed=true")
        assertInvalidation(app, category: "UIKit", duringLayout: true)
        XCTAssertTrue(app.cells["list.0"].isHittable)
        XCTAssertTrue(app.staticTexts["文章 B"].exists)
        XCTAssertFalse(app.staticTexts["文章 A"].exists)
    }


    @MainActor private func bodyApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchArguments = ["--body-controlled"]; app.launch()
        XCTAssertTrue(app.cells["categories.0"].waitForExistence(timeout: 10))
        app.cells["categories.0"].tap(); check(app, "route=list")
        app.cells["list.0"].tap(); check(app, "route=detail")
        bodyPending(app, 1)
        return app
    }
    @MainActor private func bodyPending(_ app: XCUIApplication, _ count: Int) {
        let p = NSPredicate(format: "label == %@", "pending=\(count)")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: p,
            object: app.staticTexts["body.pending"])], timeout: 5), .completed)
    }
    @MainActor func testBodyRapidSwitchRejectsLateA() {
        let app = bodyApp()
        app.cells["list.1"].tap(); check(app, "article=文章 B"); bodyPending(app, 2)
        app.buttons["body.new"].tap(); check(app, "bodyResponses=1")
        XCTAssertTrue(app.staticTexts["正文：文章 B · 新响应"].exists)
        app.buttons["body.old"].tap(); check(app, "bodyResponses=2")
        XCTAssertTrue(app.staticTexts["正文：文章 B · 新响应"].exists)
        XCTAssertFalse(app.staticTexts["正文：文章 A · 旧响应"].exists)
    }
    @MainActor func testBodyDeletionRejectsLateResponse() {
        let app = bodyApp()
        app.buttons["body.delete"].tap(); check(app, "route=list article=nil")
        app.buttons["body.old"].tap(); check(app, "bodyResponses=1")
        XCTAssertFalse(app.staticTexts["正文：文章 A · 旧响应"].exists)
        app.segmentedControls["route.mode"].buttons["窄屏"].tap(); check(app, "collapsed=true")
        XCTAssertTrue(app.cells["list.0"].isHittable)
        XCTAssertTrue(app.staticTexts["文章 B"].exists)
    }
    @MainActor func testBodyCategorySwitchRejectsLateResponse() {
        let app = bodyApp()
        app.buttons["body.switch"].tap(); check(app, "category=Swift")
        check(app, "route=list article=nil")
        app.cells["list.0"].tap(); bodyPending(app, 2)
        app.buttons["body.old"].tap(); check(app, "bodyResponses=1")
        XCTAssertTrue(app.staticTexts["正在加载正文：Swift 文章 C"].exists)
        app.buttons["body.new"].tap(); check(app, "bodyResponses=2")
        XCTAssertTrue(app.staticTexts["正文：Swift 文章 C · 新响应"].exists)
    }
    @MainActor func testBodyReloadRejectsSameArticleOldRequest() {
        let app = bodyApp()
        app.cells["detail.2"].tap(); bodyPending(app, 2)
        app.buttons["body.new"].tap(); check(app, "bodyResponses=1")
        app.buttons["body.old"].tap(); check(app, "bodyResponses=2")
        XCTAssertTrue(app.staticTexts["正文：文章 A · 新响应"].exists)
        XCTAssertFalse(app.staticTexts["正文：文章 A · 旧响应"].exists)
    }
}
