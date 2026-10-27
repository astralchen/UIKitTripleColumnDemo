// 不依赖 UIKit：把“导航结果”和“布局回调顺序”分开测试。
public enum ReadingPosition: String, Sendable {
    case categories, list, detail
}

public struct RouteLedger {
    public struct Navigation: Equatable, Sendable {
        public let id: Int
        public let source: ReadingPosition
        public let target: ReadingPosition
        public let layoutVersion: Int
        public let contentVersion: Int
    }
    public private(set) var route: ReadingPosition
    public private(set) var pending: Navigation?
    public private(set) var layoutVersion = 0
    public private(set) var contentVersion = 0
    public private(set) var needsReconciliation = false
    private var nextID = 0
    private var layouts: Set<Int> = []
    public var isChangingLayout: Bool { !layouts.isEmpty }
    public init(route: ReadingPosition = .categories) { self.route = route }

    // 只在稳定布局中开始一笔导航。请求期间继续保留 source，等待最终结果。
    public mutating func beginNavigation(to target: ReadingPosition) -> Navigation? {
        guard pending == nil, !isChangingLayout, !needsReconciliation, target != route else { return nil }
        nextID += 1
        let transaction = Navigation(id: nextID, source: route, target: target, layoutVersion: layoutVersion, contentVersion: contentVersion)
        pending = transaction
        return transaction
    }

    // 关键：不能因 layoutVersion 改变而丢弃这笔导航的最终结果。
    // 用导航 id 检查归属；内容仍有效时完成选 target、取消选 source，失效时保留已校正位置。
    @discardableResult
    public mutating func finishNavigation(id: Int, cancelled: Bool) -> Bool {
        guard let transaction = pending, transaction.id == id else { return false }
        // 内容已失效时，仅结束旧转场的等待；不再应用旧 source / target。
        if transaction.contentVersion == contentVersion {
            route = cancelled ? transaction.source : transaction.target
        } else {
            needsReconciliation = true
        }
        pending = nil
        if layoutVersion != transaction.layoutVersion { needsReconciliation = true }
        return true
    }

    // correctedRoute 由最新 ReadingLibrary 校验。外部失效事件不能被 canNavigate 丢弃。
    // 立即保存有效位置，但 pending 留到 UIKit 真正结束，防止转场中强行 show / pop。
    public mutating func contentChanged(correctedRoute: ReadingPosition, reconcile: Bool = true) {
        contentVersion += 1
        route = correctedRoute
        if reconcile || pending != nil { needsReconciliation = true }
    }

    public mutating func beginLayout() -> Int {
        nextID += 1
        layouts.insert(nextID)
        layoutVersion += 1
        if pending != nil { needsReconciliation = true }
        return nextID
    }
    public mutating func endLayout(_ id: Int) {
        guard layouts.remove(id) != nil else { return }
        layoutVersion += 1
    }

    // 布局全部结束且导航结果已知，才能消费一次校正请求。
    public mutating func takeReconciliation() -> ReadingPosition? {
        guard pending == nil, !isChangingLayout, needsReconciliation else { return nil }
        needsReconciliation = false
        return route
    }

    // 稳定状态下，无动画页面确认或宽屏的明确业务选择。
    @discardableResult
    public mutating func confirmStableRoute(_ position: ReadingPosition, version: Int, contentVersion capturedContent: Int) -> Bool {
        guard pending == nil, !isChangingLayout, !needsReconciliation,
              version == layoutVersion, capturedContent == contentVersion else { return false }
        route = position
        return true
    }
}
