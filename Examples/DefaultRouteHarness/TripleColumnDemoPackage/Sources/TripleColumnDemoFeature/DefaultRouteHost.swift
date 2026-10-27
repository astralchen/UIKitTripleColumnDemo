import UIKit
import RouteModel
@MainActor
public final class DefaultRouteHost: UIViewController {
    private let split: DefaultRouteSplit
    private let bodyService: ControlledBodyService?
    private let mode = UISegmentedControl(items: ["自动", "窄屏"])
    private let status = UILabel()
    private var narrow: NSLayoutConstraint!
    private var full: NSLayoutConstraint!
    private var contentEventInjected = false
    public init() {
        let service = ProcessInfo.processInfo.arguments.contains("--body-controlled") ? ControlledBodyService() : nil
        bodyService = service
        split = DefaultRouteSplit(bodyLoader: service ?? DemoArticleBodyLoader() as any ArticleBodyLoading)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mode.selectedSegmentIndex = 0
        mode.accessibilityIdentifier = "route.mode"
        mode.addTarget(self, action: #selector(change), for: .valueChanged)
        status.accessibilityIdentifier = "route.status"
        status.numberOfLines = 0
        let header = UIStackView(arrangedSubviews: [mode, status])
        if let service = bodyService {
            let count = UILabel(); count.accessibilityIdentifier = "body.pending"; count.text = "pending=0"
            service.onCountChange = { [weak count] in count?.text = "pending=\($0)" }
            let controls = UIStackView(); controls.distribution = .fillEqually
            for (id, title, action) in [
                ("new", "返回新请求", { service.release(newest: true) }),
                ("old", "返回旧请求", { service.release(newest: false) }),
                ("delete", "删除 A", { [weak self] in self?.split.articleWasDeleted("文章 A", in: "UIKit") }),
                ("switch", "切换 Swift", { [weak self] in self?.split.categoryWasSwitched(to: "Swift") })
            ] as [(String, String, () -> Void)] {
                let button = UIButton(type: .system); button.setTitle(title, for: .normal)
                button.accessibilityIdentifier = "body.\(id)"
                button.addAction(UIAction { _ in action() }, for: .touchUpInside)
                controls.addArrangedSubview(button)
            }
            header.addArrangedSubview(count); header.addArrangedSubview(controls)
        }
        header.axis = .vertical
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        addChild(split)
        split.view.translatesAutoresizingMaskIntoConstraints = false
        split.view.accessibilityIdentifier = "route.split"
        view.addSubview(split.view)
        full = split.view.widthAnchor.constraint(equalTo: view.widthAnchor)
        narrow = split.view.widthAnchor.constraint(equalToConstant: 390)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            split.view.topAnchor.constraint(equalTo: header.bottomAnchor),
            split.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            split.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),full])
        split.didMove(toParent: self)
        split.onStateChange = { [weak self] in self?.status.text = $0 }
        // 测试专用：在真实返回转场中改变环境，不调用模型的 finishNavigation，也不伪造取消结果。
        if ProcessInfo.processInfo.arguments.contains("--overlap-active") {
            split.onInteractiveNavigationBegan = { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.split.onInteractiveNavigationBegan = nil
                    self?.expandForTest()
                }
            }
        }
        if ProcessInfo.processInfo.arguments.contains("--overlap-decision") {
            split.onInteractiveNavigationDecision = { [weak self] in
                // 退出 UIKit 正在遍历交互回调的栈；仍在后续完成 / 回弹动画期间。
                DispatchQueue.main.async {
                    self?.split.onInteractiveNavigationDecision = nil
                    self?.expandForTest()
                }
            }
        }
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--content-delete") || arguments.contains("--content-switch") {
            let inject: @MainActor @Sendable () -> Void = { [weak self] in
                guard let self, !self.contentEventInjected else { return }
                self.contentEventInjected = true
                if arguments.contains("--content-switch") {
                    self.split.categoryWasSwitched(to: "Swift")
                } else {
                    self.split.articleWasDeleted("文章 A", in: "UIKit")
                }
                if arguments.contains("--content-expand") { self.expandForTest() }
            }
            if arguments.contains("--content-active") {
                split.onInteractiveNavigationBegan = {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: inject)
                }
            } else {
                split.onInteractiveNavigationDecision = {
                    DispatchQueue.main.async(execute: inject)
                }
            }
        }
        if arguments.contains("--content-layout-delete") {
            split.onColumnAdaptationBegan = { [weak self] in
                guard let self, !self.contentEventInjected, self.split.state.articleID != nil else { return }
                self.contentEventInjected = true
                // 在真实列转换已开始时同步接收数据事件；恢复导航仍由状态模型等待转换完成。
                self.split.articleWasDeleted("文章 A", in: "UIKit")
            }
        }
    }
    private func expandForTest() {
        mode.selectedSegmentIndex = 0
        change()
    }
    @objc private func change() {
        full.isActive = false; narrow.isActive = false
        let compact = mode.selectedSegmentIndex == 1
        (compact ? narrow : full)?.isActive = true
        if #available(iOS 17.0, *) {
            if compact { split.traitOverrides.horizontalSizeClass = .compact }
            else { split.traitOverrides.remove(UITraitHorizontalSizeClass.self) }
        } else {
            setOverrideTraitCollection(compact ? UITraitCollection(horizontalSizeClass: .compact) : nil, forChild: split)
        }
        view.layoutIfNeeded()
    }
}
