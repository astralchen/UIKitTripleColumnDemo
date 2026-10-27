import UIKit
import RouteModel

typealias DefaultReadingRoute = ReadingPosition
extension ReadingPosition {
    var column: UISplitViewController.Column {
        switch self {
        case .categories: return .primary
        case .list: return .supplementary
        case .detail: return .secondary
        }
    }
}

struct DefaultReadingState {
    var categoryID: String?
    var articleID: String?
    var route: DefaultReadingRoute = .categories
    var categoryIDs: [String] = []
    var articleIDs: [String] = []
    var bodyState: ArticleBodyState = .idle
}

// 普通页面出现凭证受布局版本约束；导航事务的最终结果另按 transactionID 接收。
@MainActor
private final class AppearanceEvidence {
    let version: Int
    let contentVersion: Int
    init(version: Int, contentVersion: Int) {
        self.version = version; self.contentVersion = contentVersion
    }
}

@MainActor
private final class DefaultReadingPage: UITableViewController {
    let position: DefaultReadingRoute
    weak var owner: DefaultRouteSplit?
    private var evidence: AppearanceEvidence?
    private var rows: [String] = []
    private var articleCount = 0

    init(_ position: DefaultReadingRoute) {
        self.position = position
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("使用代码初始化") }

    func render(_ state: DefaultReadingState) {
        switch position {
        case .categories:
            title = "分类"; rows = state.categoryIDs
        case .list:
            title = state.categoryID.map { "\($0) 列表" } ?? "请选择分类"
            articleCount = state.articleIDs.count
            rows = state.categoryID == nil ? [] : state.articleIDs + ["返回分类（业务操作）"]
        case .detail:
            title = state.articleID ?? "文章已删除或未选择"
            let body: String
            switch state.bodyState {
            case .idle: body = "请选择文章或重新加载"
            case .loading: body = "正在加载正文：\(state.articleID ?? "无")"
            case .loaded(_, let text): body = text
            case .failed(_, let message): body = "加载失败：\(message)"
            }
            rows = [body, "返回列表（业务操作）", "重新加载正文"]
        }
        // 方便观察 route；系统返回按钮由 UIKit 自己生成，不替换 leftBarButtonItem。
        navigationItem.prompt = "route=\(state.route.rawValue) · article=\(state.articleID ?? "nil")"
        if isViewLoaded { tableView.reloadData() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        evidence = owner?.pageWillAppear(self, coordinator: transitionCoordinator)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        owner?.pageDidAppear(self, evidence: evidence)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        evidence = nil // 只作废页面出现证据，不作废正在等待结果的导航事务。
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = rows[indexPath.row]
        cell.accessibilityIdentifier = "\(position.rawValue).\(indexPath.row)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard rows.indices.contains(indexPath.row) else { return }
        switch position {
        case .categories: owner?.selectCategory(rows[indexPath.row])
        case .list:
            if indexPath.row < articleCount { owner?.selectArticle(rows[indexPath.row]) }
            else { owner?.go(to: .categories) }
        case .detail:
            if indexPath.row == 1 { owner?.go(to: .list) }
            if indexPath.row == 2 { owner?.reloadArticleBody() }
        }
    }
}

@MainActor
final class DefaultRouteSplit: UISplitViewController, UISplitViewControllerDelegate {
    private(set) var state: DefaultReadingState
    private var ledger: RouteLedger
    private var library: ReadingLibrary
    private let body: ArticleBodyCoordinator
    var onStateChange: ((String) -> Void)?
    // 仅供验证外壳在真实交互转场开始后触发布局变化，不伪造导航结果。
    var onInteractiveNavigationBegan: (() -> Void)?
    var onInteractiveNavigationDecision: (() -> Void)?
    var onColumnAdaptationBegan: (() -> Void)?
    private let categories = DefaultReadingPage(.categories)
    private let list = DefaultReadingPage(.list)
    private let detail = DefaultReadingPage(.detail)
    private var pages: [DefaultReadingPage] { [categories, list, detail] }
    private var columnLayoutID: Int?
    private var restoring = false
    private var hasAppeared = false
    private var reconciliationScheduled = false
    private var navigationCoordinator: UIViewControllerTransitionCoordinator?
    private var completionQueued = true
    private var lastResult = "none"
    private var overlaps = 0
    private var cancellations = 0
    private var invalidationsDuringNavigation = 0
    private var invalidationsDuringLayout = 0
    private var ignoredContentResults = 0
    private var bodyResponses = 0

    init(state: DefaultReadingState = DefaultReadingState(),
         catalog: [String: [String]] = ReadingLibrary.demoCatalog,
         bodyLoader: any ArticleBodyLoading = DemoArticleBodyLoader()) {
        body = ArticleBodyCoordinator(loader: bodyLoader)
        library = ReadingLibrary(catalog: catalog, categoryID: state.categoryID, articleID: state.articleID)
        var initial = state
        initial.route = library.correctedRoute(initial.route)
        self.state = initial
        ledger = RouteLedger(route: initial.route)
        super.init(style: .tripleColumn)
        delegate = self
        preferredSplitBehavior = .tile
        preferredDisplayMode = .twoBesideSecondary
        minimumPrimaryColumnWidth = 200
        maximumPrimaryColumnWidth = 320
        preferredPrimaryColumnWidth = 240
        minimumSupplementaryColumnWidth = 240
        maximumSupplementaryColumnWidth = 380
        preferredSupplementaryColumnWidth = 280
        for page in pages {
            page.owner = self
            setViewController(UINavigationController(rootViewController: page), for: page.position.column)
        }
        body.onResponseProcessed = { [weak self] _, _ in
            guard let self else { return }
            self.bodyResponses += 1
            self.publish()
        }
        body.onChange = { [weak self] in self?.renderBody() }
        // 不设置 .compact；不接管列导航代理，也不替换系统 Back 和边缘返回手势。
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("使用代码初始化") }

    private var canObserve: Bool {
        hasAppeared && isCollapsed && !restoring && !ledger.isChangingLayout && !ledger.needsReconciliation
    }
    private var canNavigate: Bool {
        hasAppeared && !restoring && !ledger.isChangingLayout && ledger.pending == nil &&
        !ledger.needsReconciliation && transitionCoordinator == nil &&
        pages.allSatisfy { $0.transitionCoordinator == nil }
    }

    fileprivate func pageWillAppear(_ page: DefaultReadingPage,
        coordinator: UIViewControllerTransitionCoordinator?) -> AppearanceEvidence? {
        guard canObserve, library.correctedRoute(page.position) == page.position else { return nil }
        if let coordinator, let transaction = ledger.beginNavigation(to: page.position) {
            // 捕获这笔真实导航的 source/target。布局版本改变后仍必须接收它的最终结果。
            navigationCoordinator = coordinator
            completionQueued = coordinator.animate(alongsideTransition: nil) { [weak self] context in
                self?.navigationFinished(id: transaction.id, cancelled: context.isCancelled)
            }
            if coordinator.initiallyInteractive {
                coordinator.notifyWhenInteractionChanges { [weak self] _ in
                    self?.onInteractiveNavigationDecision?() // 验证接口，不在此提交 route。
                }
                onInteractiveNavigationBegan?()
            }
            return nil
        }
        guard ledger.pending == nil else { return nil }
        return AppearanceEvidence(version: ledger.layoutVersion, contentVersion: ledger.contentVersion)
    }

    fileprivate func pageDidAppear(_ page: DefaultReadingPage, evidence: AppearanceEvidence?) {
        // animate 返回 false 时完成块仍可能执行。若页面先完成出现，可按同一事务幂等结算。
        if !completionQueued, let transaction = ledger.pending, let coordinator = navigationCoordinator,
           !ledger.isChangingLayout, !restoring {
            let expected = coordinator.isCancelled ? transaction.source : transaction.target
            if page.position == expected {
                navigationFinished(id: transaction.id, cancelled: coordinator.isCancelled)
            }
        }
        guard canObserve, let evidence, page.viewIfLoaded?.window != nil else { return }
        // 无动画 / 普通页面确认只能在稳定布局中写入；过期版本或 pending 存在时模型会拒绝。
        guard library.correctedRoute(page.position) == page.position else { return }
        if ledger.confirmStableRoute(page.position, version: evidence.version,
                                     contentVersion: evidence.contentVersion) { refresh() }
    }

    private func navigationFinished(id: Int, cancelled: Bool) {
        // 不使用布局 generation 拒绝本回调；按 transactionID 校验，重复和过期结果无效。
        let obsoleteContent = ledger.pending.map { $0.contentVersion != ledger.contentVersion } ?? false
        guard ledger.finishNavigation(id: id, cancelled: cancelled) else { return }
        if obsoleteContent { ignoredContentResults += 1 }
        navigationCoordinator = nil
        lastResult = cancelled ? "cancelled" : "completed"
        if cancelled { cancellations += 1 }
        refresh()
        scheduleReconciliation()
    }

    fileprivate func selectCategory(_ id: String) {
        guard canNavigate else { return }
        guard library.categoryIDs.contains(id) else { return }
        if library.selectCategory(id) {
            ledger.contentChanged(correctedRoute: library.correctedRoute(ledger.route), reconcile: false)
        }
        refresh(); go(to: .list)
    }
    fileprivate func selectArticle(_ id: String) {
        guard canNavigate, library.articleIDs.contains(id) else { return }
        if library.selectArticle(id) {
            ledger.contentChanged(correctedRoute: library.correctedRoute(ledger.route), reconcile: false)
        }
        refresh(); go(to: .detail)
    }
    fileprivate func go(to requested: DefaultReadingRoute) {
        guard canNavigate else { return }
        let destination = library.correctedRoute(requested)
        if !isCollapsed {
            ledger.confirmStableRoute(destination, version: ledger.layoutVersion,
                                      contentVersion: ledger.contentVersion)
            refresh() // 宽屏 route 由明确业务点击决定，不由各页出现顺序决定。
        }
        show(destination.column)
    }
    // 数据事件不能使用 canNavigate 过滤，否则动画期间发生的删除会丢失。
    func articleWasDeleted(_ id: String, in category: String) {
        updateCatalog { $0.deleteArticle(id, in: category) }
    }
    func categoryWasDeleted(_ id: String) {
        updateCatalog { $0.deleteCategory(id) }
    }
    func catalogWasReplaced(_ snapshot: [String: [String]]) {
        updateCatalog { $0.replaceCatalog(snapshot) }
    }
    func categoryWasSwitched(to id: String) {
        guard library.selectCategory(id) else { return }
        invalidateSelection(to: .list) // 明确的切换分类意图：进入新分类列表。
    }
    private func updateCatalog(_ update: (inout ReadingLibrary) -> Void) {
        let oldCategory = library.categoryID
        let oldArticle = library.articleID
        update(&library)
        if oldCategory != library.categoryID || oldArticle != library.articleID {
            invalidateSelection(to: library.correctedRoute(ledger.route))
        } else {
            refresh() // 删除无关文章只刷新数据，不取消仍然有效的返回意图。
        }
    }
    private func invalidateSelection(to route: ReadingPosition) {
        if ledger.pending != nil { invalidationsDuringNavigation += 1 }
        if ledger.isChangingLayout { invalidationsDuringLayout += 1 }
        ledger.contentChanged(correctedRoute: library.correctedRoute(route))
        // 立即清空旧正文；等待转场结束的是容器导航，而不是删除这件业务事实。
        refresh()
        scheduleReconciliation()
    }
    fileprivate func reloadArticleBody() { body.reload() }
    // 正文更新只渲染；不会把 route=list 的用户重新带回详情。
    private func renderBody() {
        state.bodyState = body.state
        pages.forEach { $0.render(state) }
        publish()
    }
    private func refresh() {
        state.categoryID = library.categoryID
        state.articleID = library.articleID
        state.categoryIDs = library.categoryIDs
        state.articleIDs = library.articleIDs
        state.route = ledger.route
        let context: ArticleBodyContext?
        if let category = library.categoryID, let article = library.articleID,
           library.articleIDs.contains(article) {
            context = ArticleBodyContext(categoryID: category, articleID: article,
                                         contentVersion: ledger.contentVersion)
        } else { context = nil }
        body.synchronize(context: context)
        renderBody()
    }
    private func publish() {
        onStateChange?("route=\(ledger.route.rawValue) article=\(state.articleID ?? "nil") " +
            "collapsed=\(isCollapsed) cancelled=\(cancellations) result=\(lastResult) " +
            "pending=\(ledger.pending != nil) layout=\(ledger.isChangingLayout) " +
            "restore=\(restoring) overlap=\(overlaps) category=\(state.categoryID ?? "nil") " +
            "content=\(ledger.contentVersion) invalidNav=\(invalidationsDuringNavigation) " +
            "invalidLayout=\(invalidationsDuringLayout) ignoredContent=\(ignoredContentResults) bodyResponses=\(bodyResponses)")
    }

    // 导航和布局都结束后，退出当前 UIKit 回调栈再做一次校正。不是固定延迟猜动画时间。
    private func scheduleReconciliation() {
        guard !reconciliationScheduled else { return }
        reconciliationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reconciliationScheduled = false
            guard !self.restoring, self.hasAppeared,
                  let route = self.ledger.takeReconciliation() else { return }
            if self.isCollapsed { self.restoreCollapsedRoute(route) }
            else { self.refresh() } // 展开只同步数据，下次折叠使用最终 route。
        }
    }
    private func restoreCollapsedRoute(_ route: ReadingPosition) {
        restoring = true
        let layout = ledger.beginLayout()
        show(route.column) // 可能返回、前进或无需操作；不手工操作 UIKit 的内部导航栈。
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.finishRestoration(layout)
            }
        } else {
            finishRestoration(layout)
        }
    }
    private func finishRestoration(_ layout: Int) {
        ledger.endLayout(layout)
        restoring = false
        refresh()
        scheduleReconciliation()
    }
    private func beginLayout() -> Int {
        if ledger.pending != nil { overlaps += 1 }
        return ledger.beginLayout()
    }
    private func endLayout(_ id: Int) {
        ledger.endLayout(id)
        refresh()
        scheduleReconciliation()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAppeared else { return }
        hasAppeared = true
        if isCollapsed { restoreCollapsedRoute(ledger.route) }
        publish()
    }
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        let layout = beginLayout()
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in self?.endLayout(layout) }
    }
    private func beginColumnAdaptation() {
        if columnLayoutID == nil {
            columnLayoutID = beginLayout()
            onColumnAdaptationBegan?() // 测试可在真实布局转换开始后注入数据事件。
        }
    }
    private func finishColumnAdaptation() {
        guard let id = columnLayoutID else { return }
        columnLayoutID = nil; endLayout(id)
    }
    func splitViewController(_ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: Column) -> Column {
        beginColumnAdaptation()
        // 结果未定时暂用最后提交的位置；若结果晚到，scheduleReconciliation 再校正。
        return ledger.route.column
    }
    func splitViewController(_ svc: UISplitViewController,
        displayModeForExpandingToProposedDisplayMode proposedDisplayMode: DisplayMode) -> DisplayMode {
        beginColumnAdaptation(); return .twoBesideSecondary
    }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) { finishColumnAdaptation() }
    func splitViewControllerDidExpand(_ svc: UISplitViewController) { finishColumnAdaptation() }
}
