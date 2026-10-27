// UISplitViewController 中文注释版 · 四个核心概念与三栏示例
//
// 本文件是 SDK 接口阅读稿：原始声明、顺序、枚举原始值及版本标记均保留。
// 示意图和示例代码全部写在注释中，不属于下面的 SDK 声明。
// 文件包含无实现体的 SDK 接口，不要整份加入 App 的编译目标。
// 下面的基本三栏配置可用于最低部署 iOS 15 的项目。
//
// MARK: - 1. 先从“分类 → 文章列表 → 文章详情”理解四个概念
//
// 假设你已经创建三个内容控制器：
//   categoryVC：分类，例如“UIKit 布局”“示例笔记”。
//   listVC：选中分类中的文章列表。
//   detailVC：选中文章的正文。
//
// 四个概念分别回答四个问题：
//
//   Style         容器采用哪种结构？
//                 .tripleColumn 表示采用三栏结构，但不要求三列始终同时可见。
//
//   Column        某个内容控制器属于哪个位置？
//                 .primary 放分类，.supplementary 放列表，.secondary 放详情。
//                 隐藏一列不会改变它的身份，也不会自动删除它的内容配置。
//
//   SplitBehavior 侧栏出现时，如何与详情共处？
//                 .tile 并排分配空间；.overlay 盖住详情；.displace 把详情推开。
//                 这套规则会限制可采用的 DisplayMode。
//
//   DisplayMode   按照这套规则，具体显示哪些普通内容列、怎样排列？
//                 例如只显示详情、列表与详情并排、三栏并排。
//                 preferredDisplayMode 是请求，displayMode 是实际结果。
//
// MARK: - 2. 结构、内容位置、布局规则、显示结果之间的关系
//
//   Style = .tripleColumn
//          |
//          | 决定采用三栏结构
//          v
//   +----------------+---------------------+------------------+
//   | primary (P)    | supplementary (S)   | secondary (D)    |
//   | categoryVC     | listVC              | detailVC         |
//   +----------------+---------------------+------------------+
//     分类位置         文章列表位置          文章详情位置
//          |
//          | setViewController(_:for:) 为各位置提供内容
//          v
//   preferredSplitBehavior：请求并排 / 覆盖 / 挤移
//          |
//          | 实际 splitBehavior 限制可选显示模式
//          v
//   preferredDisplayMode：请求一个与结构和行为兼容的显示组合
//          |
//          | UIKit 综合可用空间、列宽、窗口环境等条件进行布局
//          v
//   displayMode：当前实际模式       isCollapsed：是否已折叠
//
// 注意：这张图说明配置关系，不表示 UIKit 会按这些步骤逐个调用代理。
// 隐藏到只剩详情后，Style 仍是 tripleColumn，详情的 Column 仍是 secondary。
// 想让某一列出现，可以直接调用 show(_ column:)，让 UIKit 选择合适的显示模式。
//
// MARK: - 3. 同一个三栏容器：并排、覆盖、挤移的区别
//
// 图例：P = primary 分类，S = supplementary 列表，D = secondary 详情。
// 以下均是假设“界面已展开、已有三列内容、空间允许”的示意，不含 inspector。
// 图中宽度不代表实际点数；语言方向以中文常见的从左到右布局为例。
//
// A. tile + twoBesideSecondary：三栏并排，各占一块空间。
//
//   可视窗口
//   +----------+-------------+------------------------+
//   |    P     |      S      |           D            |
//   +----------+-------------+------------------------+
//
//   P、S、D 均可见、可交互。“two”表示详情之外有两个侧栏，合计三列。
//   tile 只是并排规则；它本身并不意味着必须同时显示三列。
//
// B. overlay + twoOverSecondary：P、S 盖在 D 上，D 保持在底层。
//
//   底层详情原本占据的区域：
//   +-------------------------------------------------+
//   |                        D                        |
//   +-------------------------------------------------+
//   上层覆盖区域：
//   +----------+-------------+
//   |    P     |      S      |
//   +----------+-------------+
//   合成后的可见效果：
//   +----------+-------------+------------------------+
//   |    P     |      S      |   D 的剩余可见区域      |
//   +----------+-------------+------------------------+
//
//   D 左侧被遮住；露出的详情区域会变暗，不能直接操作其内容。
//   与 tile 的关键区别：不是给 D 缩出一块并排空间，而是把侧栏盖上去。
//
// C. displace + twoDisplaceSecondary：加入 P 时，把原来的 S、D 向另一侧推移。
//
//   只有 S 与 D 时（oneBesideSecondary）：
//   +-------------+-----------------------------------+
//   |      S      |                 D                 |
//   +-------------+-----------------------------------+
//
//   P 出现后（twoDisplaceSecondary）：
//   +----------+-------------+------------------------+-----------+
//   |    P     |      S      |        D 可见部分      : D 屏幕外  |
//   +----------+-------------+------------------------+-----------+
//   ^                                                ^
//   窗口起点                                         窗口右边界
//
//   P、S、D 保持相邻排列；D 的一部分越过窗口边界，被裁切并加上遮罩。
//   与 overlay 的关键区别：详情被推移了，不是留在原地让侧栏盖住。
//
// MARK: - 4. SplitBehavior 允许哪些 DisplayMode（三栏情况）
//
//   .tile
//      .secondaryOnly          [ D ]
//      .oneBesideSecondary     [ S ][ D ]
//      .twoBesideSecondary     [ P ][ S ][ D ]，三栏并排
//
//   .overlay
//      .secondaryOnly          [ D ]
//      .oneOverSecondary       S 覆盖在 D 上，P 隐藏
//      .twoOverSecondary       P、S 并排覆盖在 D 上
//
//   .displace
//      .secondaryOnly          [ D ]
//      .oneBesideSecondary     [ S ][ D ]
//      .twoDisplaceSecondary   [ P ][ S ][ D ... ]，D 的一部分移到窗口外
//
// 易错点：三栏中的 oneBesideSecondary 显示 S + D，不是 P + D。
// 双栏没有 supplementary，因此双栏中的 oneBesideSecondary 才是 P + D。
// 不要任意拼接行为与模式，例如 .tile 与 .twoOverSecondary 不是兼容组合。
// .automatic 表示让系统选择，不是上述示意图之外的一种固定布局。
//
// MARK: - 5. 三栏配置代码（复制到自己的业务源文件，保留 UIKit import）
//
// import UIKit
//
// @MainActor
// func makeThreeColumnSplit(
//     categoryVC: UIViewController,
//     listVC: UIViewController,
//     detailVC: UIViewController
// ) -> UISplitViewController {
//     // ① Style：创建三栏结构。这一步还没有放入业务内容。
//     let split = UISplitViewController(style: .tripleColumn)
//
//     // ② Column：为三个内容位置分别配置控制器。
//     // 显式使用 UINavigationController，为各列提供导航栏与导航能力。
//     split.setViewController(
//         UINavigationController(rootViewController: categoryVC), for: .primary
//     )
//     split.setViewController(
//         UINavigationController(rootViewController: listVC), for: .supplementary
//     )
//     split.setViewController(
//         UINavigationController(rootViewController: detailVC), for: .secondary
//     )
//
//     // ③ SplitBehavior：希望侧栏与详情并排分配空间。
//     split.preferredSplitBehavior = .tile
//
//     // ④ DisplayMode：在并排规则下，希望三个内容列都出现。
//     split.preferredDisplayMode = .twoBesideSecondary
//
//     // 列宽是附加的布局偏好，不改变 Style，也不改变 Column 的身份。
//     split.minimumPrimaryColumnWidth = 200
//     split.maximumPrimaryColumnWidth = 320
//     split.preferredPrimaryColumnWidth = 240
//     split.minimumSupplementaryColumnWidth = 240
//     split.maximumSupplementaryColumnWidth = 380
//     split.preferredSupplementaryColumnWidth = 280
//
//     // 不设置 .compact，让 UIKit 处理已有内容列的默认折叠导航。
//     return split
// }
//
// 使用方式：传入你已创建的分类、列表、详情控制器，再把返回的 split 放入窗口。
// 这里负责容器配置；用户选中分类 / 文章后的数据更新，由你的业务代码处理。
//
// MARK: - 6. 保留结构和内容，只切换布局规则与显示组合
//
// 以下三组配置是可供选择的状态示例，不需要在初始化时连续执行三遍。
// 假设 split 是上面创建的同一个容器，P、S、D 的内容配置一直保留。
//
// A. 同时看三列，并排展示：
//   split.preferredSplitBehavior = .tile
//   split.preferredDisplayMode = .twoBesideSecondary
//
// B. 同时打开两个侧栏，让它们覆盖在详情上：
//   split.preferredSplitBehavior = .overlay
//   split.preferredDisplayMode = .twoOverSecondary
//
// C. 同时打开两个侧栏，让它们把详情推走一部分：
//   split.preferredSplitBehavior = .displace
//   split.preferredDisplayMode = .twoDisplaceSecondary
//
// 如果只需要临时专注阅读，三种行为都允许请求只显示详情：
//   split.preferredDisplayMode = .secondaryOnly
// 这不会把 style 改成双栏，也不会删除 primary / supplementary 的内容。
//
// 如果是用户点击文章后的导航，不必自己计算模式组合：
//   // 先把选中文章的数据更新到 detailVC。
//   split.show(.secondary)
// 展开时详情可能已经可见；默认折叠导航中，UIKit 会将详情列带到顶部。
//
// 需要观察结果时，在布局 / 转场完成后读取，而不是设置偏好后立即假设已生效：
//   let actualBehavior = split.splitBehavior
//   let actualMode = split.displayMode
//   let collapsed = split.isCollapsed
//
// MARK: - 7. 先分清“环境”“状态”和“.compact 内容槽位”
//
//   horizontalSizeClass == .compact   环境：当前横向空间属于紧凑尺寸类别。
//   split.isCollapsed == true         状态：分栏内容已折叠成单个呈现容器。
//   UISplitViewController.Column.compact
//                                    槽位：可选的、专供折叠界面使用的控制器。
//
// 上面的两个 .compact 属于不同枚举，不能互相替代。
// setViewController(vc, for: .compact) 是“准备折叠时使用的页面”，不会主动触发折叠。
// isCollapsed 只读，不能赋值；也不要把 .compact 当成第四个并排显示的普通内容列。
//
// 本文“窄屏 / 宽屏”指容器的横向环境变为 compact / regular 的典型适配过程，
// 不规定某个固定点数阈值，也不按 iPhone / iPad 或横竖屏硬编码。
// 窗口缩窄但横向环境仍为 regular 时，可能只是隐藏部分列，尚未发生语义上的折叠。
// 因此实际布局状态看 isCollapsed；普通列的可见组合在展开时看 displayMode。
//
//   isCollapsed == false + .twoBesideSecondary  → [分类 P] [列表 S] [详情 D]
//   isCollapsed == false + .secondaryOnly       → [       详情 D       ]
//   isCollapsed == true                        → [折叠导航 / compact 页面]
//
// 第二行虽然只看到详情，仍然是展开状态；第三行的外观不由 DisplayMode 控制。
// Style 一直是 .tripleColumn，不会因为窗口变窄自动变成 .doubleColumn。
//
// MARK: - 8. 不配置 .compact：让 UIKit 折叠现有三列
//
// 以下示意图描述业务上的导航层级，不代表 UIKit 内部 viewControllers 数组的精确结构。
// P = primary 分类，S = supplementary 列表，D = secondary 详情。
//
// 【宽 → 窄】已选文章 A，希望折叠后继续阅读 A：
//
//   ① 宽屏稳定状态                    [P 分类] [S 列表] [D 文章 A]
//      isCollapsed == false                       |
//   ② 横向环境 regular → compact，UIKit 开始适配   v
//   ③ 调用 topColumnForCollapsingToProposedTopColumn
//      你读取业务选择状态，返回 .secondary          |
//      （是在选择“转换后看哪列”，不是手动 push）   v
//   ④ UIKit 组织折叠导航                 [P] → [S] → [D 文章 A]
//                                                     ^ 顶部可见
//   ⑤ splitViewControllerDidCollapse：已折叠，isCollapsed == true
//
// 没有选择文章时，可以返回 .primary 从分类开始；也可以根据业务返回 .supplementary。
// 没有自定义决策时，省略代理方法，或原样返回 proposedTopColumn，接受系统建议。
// 折叠后用户再点文章：先更新详情数据，再 show(.secondary)，由 UIKit 完成列式导航。
// 不要同时手动把同一个详情控制器 push 到另一个导航控制器中。
//
// 【窄 → 宽】继续显示刚才选中的文章 A：
//
//   ① 窄屏稳定状态                      [P] → [S] → [D 文章 A]
//      isCollapsed == true                         |
//   ② 横向环境 compact → regular，UIKit 开始适配   v
//   ③ 调用 displayModeForExpandingToProposedDisplayMode
//      先同步选中内容，再返回 .twoBesideSecondary   |
//      （这里返回 DisplayMode，不返回 Column）     v
//   ④ UIKit 恢复展开布局                [P 分类] [S 列表] [D 文章 A]
//   ⑤ splitViewControllerDidExpand：已展开，isCollapsed == false
//      此时可读取实际 displayMode / splitBehavior / 列宽，更新界面提示。
//
// 两个决策代理分别回答：
//   折叠：单个呈现容器中“先看哪一列”？        → 返回 Column。
//   展开：多个普通内容列“采用哪种可见排列”？  → 返回 DisplayMode。
// 它们都不会替你保存文章 ID、加载正文或同步滚动位置，这些属于 App 的业务状态。
// .twoBesideSecondary 要配合 .tripleColumn / .tile；其他配置可返回 proposedDisplayMode。
//
// 【isCollapsed 的读取时机】
// 两个决策回调是在转换过程中调用的，此时 isCollapsed 可能仍表示转换前的状态。
// 不要在折叠回调里写 guard svc.isCollapsed else { ... } 来判断是否需要折叠。
// 不要在展开回调里写 guard !svc.isCollapsed else { ... } 来判断是否需要展开。
// 回调名称已经说明正在处理哪一种转换；返回值描述目标，isCollapsed 描述当前状态。
// didCollapse / didExpand 是完成通知，适合观察结果；不要在其中再触发相反的布局切换。
// 上图是决策与结果的示意，未列出所有 willShow / didShow / willHide / didHide 回调，
// 也不表示这些列级回调之间有固定顺序，或所有动画都已在通知时结束。
//
// MARK: - 9. 配置独立 .compact：同一份业务状态，两套页面
//
// 当窄屏需要完全不同的内容组织方式时，才需要独立的 .compact 控制器。
// 例如宽屏保持三栏，窄屏改用自己管理的“分类 → 列表 → 详情”导航：
//
//                  共享业务状态：分类 ID / 文章 ID
//                          /                 \
//                         v                   v
//   展开视图树：[P 分类] [S 列表] [D 文章 A]   折叠视图树：compactNav
//                         |                     [分类] → [列表] → [文章 A]
//                         |                                      ^ 顶部
//                         +-- 不同控制器实例，只共享数据 -----------+
//
// 宽 → 窄：topColumn... 中把当前选择同步给 compact 页面，再返回 .compact。
// 窄 → 宽：displayModeForExpanding... 中把 compact 中的最新选择同步到三栏，
//          再返回 .twoBesideSecondary；UIKit 恢复普通列，不会帮你拆解自定义导航栈。
//
// 必须先 setViewController(compactNav, for: .compact)，才有对应的折叠页面可显示。
// 配置后，折叠界面由这个控制器承担；不要再依赖默认三列导航来组织它内部的 push/pop。
// .compact 是可选项：没有配置它，UIKit 也能折叠；配置它并不会禁止折叠代理参与决策。
// .compact 内部用自己的导航控制器 push/pop，不使用 show(.compact) / hide(.compact)。
// 一个 UIViewController 实例不能同时挂在普通列和 compact 导航栈中；应创建独立实例。
//
// 首次启动就处于窄屏时，也必须有可用内容：在初始化时准备页面和状态，
// 不要把唯一一次数据加载放在“由宽变窄”的代理里，也不要依赖首屏一定走某次转换回调。
//
// MARK: - 10. 两条路径共用的示例代码（最低 iOS 15）
//
// 下面是独立的教学示例，复制时去掉每行最外层的“// ”，放入 App 源文件。
// AdaptiveArticleSplit() 使用 UIKit 默认折叠；传 true 则演示独立 compact 导航。
// 这里用带标题的空白页面聚焦容器与代理；分类 / 文章列表点击事件分别调用
// selectCategory(_:) / selectArticle(_:)。完整列表 UI 可沿用 UIKitTripleColumnDemo。
// 此示例采用“有选中文章就继续阅读”的策略；返回上一级不自动清空文章选择。
// 若需要恢复返回后的位置，请继续看第 16～19 节独立的 route 示例。
// 如果需要精确恢复用户返回后的页面，应另存当前路由，不能只看 selectedArticleID。
//
// BEGIN_ADAPTIVE_EXAMPLE
// import UIKit
//
// @MainActor
// final class AdaptiveArticleSplit: UISplitViewController, UISplitViewControllerDelegate {
//     // 容器统一持有业务状态；两套页面的用户操作都通过下面的选择方法更新它。
//     private var selectedCategoryID: String?
//     private var selectedArticleID: String?
//     private let usesCompactInterface: Bool
//
//     private let categoryPage = UIViewController()
//     private let listPage = UIViewController()
//     private let detailPage = UIViewController()
//     private let compactNavigation = UINavigationController()
//
//     init(usesCompactInterface: Bool = false) {
//         self.usesCompactInterface = usesCompactInterface
//         super.init(style: .tripleColumn)
//         delegate = self  // delegate 是弱引用；这里由 split 自己实现代理。
//         preferredSplitBehavior = .tile
//         preferredDisplayMode = .twoBesideSecondary
//         minimumPrimaryColumnWidth = 200
//         maximumPrimaryColumnWidth = 320
//         preferredPrimaryColumnWidth = 240
//         minimumSupplementaryColumnWidth = 240
//         maximumSupplementaryColumnWidth = 380
//         preferredSupplementaryColumnWidth = 280
//
//         for (page, column) in [
//             (categoryPage, Column.primary),
//             (listPage, Column.supplementary),
//             (detailPage, Column.secondary)
//         ] {
//             page.view.backgroundColor = .systemBackground
//             setViewController(UINavigationController(rootViewController: page), for: column)
//         }
//         refreshExpandedPages()  // 首屏数据准备不依赖转换回调。
//         if usesCompactInterface {
//             rebuildCompactStack()
//             setViewController(compactNavigation, for: .compact)
//         }
//     }
//
//     required init?(coder: NSCoder) { fatalError("请使用代码初始化") }
//
//     // 由分类页的点击事件调用；换分类时清除旧文章，防止列表与详情不一致。
//     func selectCategory(_ id: String) {
//         selectedCategoryID = id
//         selectedArticleID = nil
//         refreshExpandedPages()
//         if usesCompactInterface && isCollapsed {
//             rebuildCompactStack()
//         } else {
//             show(.supplementary)
//         }
//     }
//
//     // 由文章列表的点击事件调用。此处发生在稳定界面中，可用 isCollapsed 选择导航方式。
//     func selectArticle(_ id: String) {
//         guard selectedCategoryID != nil else { return }
//         selectedArticleID = id
//         refreshExpandedPages()
//         if usesCompactInterface && isCollapsed {
//             rebuildCompactStack()  // 自己管理 compact 内部导航。
//         } else {
//             show(.secondary)      // 默认折叠时由 UIKit 导航；展开时此调用被忽略，详情已更新。
//         }
//     }
//
//     private func refreshExpandedPages() {
//         categoryPage.title = "分类"
//         listPage.title = selectedCategoryID.map { "分类：\($0)" } ?? "请选择分类"
//         detailPage.title = selectedArticleID.map { "文章：\($0)" } ?? "请选择文章"
//         // 真实项目在此用 ID 更新列表选中项、正文和各自保存的滚动位置。
//     }
//
//     private func rebuildCompactStack() {
//         // 教学示例从选择状态重建路由；每页都是独立实例，不复用普通列的控制器。
//         // 真实项目宜复用 compact 自己的页面，并保存滚动位置、编辑内容等临时状态。
//         func page(_ title: String) -> UIViewController {
//             let page = UIViewController()
//             page.title = title
//             page.view.backgroundColor = .systemBackground
//             return page
//         }
//         var stack = [page("分类")]
//         if let categoryID = selectedCategoryID { stack.append(page("分类：\(categoryID)")) }
//         if let articleID = selectedArticleID { stack.append(page("文章：\(articleID)")) }
//         compactNavigation.setViewControllers(stack, animated: false)
//     }
//
//     // 决策 1：折叠后的目标 Column。不要根据此刻的 isCollapsed 再判断转换方向。
//     func splitViewController(
//         _ svc: UISplitViewController,
//         topColumnForCollapsingToProposedTopColumn proposedTopColumn: Column
//     ) -> Column {
//         if usesCompactInterface {
//             rebuildCompactStack()  // 先准备已配置的 compact 页面的目标内容。
//             return .compact
//         }
//         if selectedArticleID != nil { return .secondary }
//         if selectedCategoryID != nil { return .supplementary }
//         return .primary
//         // 若不需要以上业务策略，可直接 return proposedTopColumn。
//     }
//
//     // 决策 2：展开后的 DisplayMode。业务数据与容器布局分别处理。
//     func splitViewController(
//         _ svc: UISplitViewController,
//         displayModeForExpandingToProposedDisplayMode proposedDisplayMode: DisplayMode
//     ) -> DisplayMode {
//         refreshExpandedPages()  // compact 页面的操作已通过选择方法写入共享状态。
//         return .twoBesideSecondary  // 本例固定 tripleColumn + tile，恢复三栏并排。
//         // 若由系统决定展开排列，可直接 return proposedDisplayMode。
//     }
//
//     // 以下是完成通知，返回 Void；与上面的两个“决策代理”职责不同。
//     func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
//         print("已折叠，isCollapsed = \(svc.isCollapsed)")
//     }
//
//     func splitViewControllerDidExpand(_ svc: UISplitViewController) {
//         print("已展开，isCollapsed = \(svc.isCollapsed)，实际模式 = \(svc.displayMode)")
//     }
// }
// END_ADAPTIVE_EXAMPLE
//
// 两个用法任选一个作为 UIWindow.rootViewController，无需额外包一层导航控制器：
//   let split = AdaptiveArticleSplit()                           // 默认折叠导航
//   let split = AdaptiveArticleSplit(usesCompactInterface: true) // 独立 compact 页面
// 在列表 UI 尚未接入时，可先调用以下两行准备“正在阅读 A”的状态，再调整窗口大小：
//   split.selectCategory("UIKit")
//   split.selectArticle("A")
//
// MARK: - 11. show(_:) / hide(_:)：先确认是哪一组 API
//
// 本节讨论列式 API：
//   split.show(.primary)       // 参数是 UISplitViewController.Column。
//   split.hide(.supplementary)
// 不要与 show(nextVC, sender: self) 混淆；后者接收 UIViewController，属于另一组展示 API。
// setViewController(_:for:) 配置“这列装谁”；show / hide 请求“当前如何呈现已配置的列”。
// show 不加载文章，hide 不清空选中项，也不移除该列的配置。
//
// 本节普通列规则限于 primary / supplementary / secondary，假设均已配置。
// iOS 26 inspector 是独立辅助呈现，另见后文；不要把以下三层导航规则套到 inspector。
// show / hide 都不接受 Column.compact：它不是可以开关的第四个普通列。
//
// 三种情况的职责对照：
//   展开（isCollapsed == false）
//     show / hide 调整普通列的可见组合；UIKit 选择当前 SplitBehavior 允许的最近模式。
//   默认折叠（isCollapsed == true，未配置独立 compact）
//     show / hide 操作 UIKit 组织的列导航层级；show 可前进或返回，hide 有条件地返回。
//   独立 compact（isCollapsed == true，已配置 compact 页面）
//     当前呈现的是 compact 控制器；App 用它自己的导航 API 管理其中的业务页面。
//     compact 内部的分类 / 列表 / 详情并不是 split 的三个普通 Column。
//     因而不能指望 show(.secondary) 把 compact 内部详情 push 出来，
//     也不能用 hide(.secondary) 代替 compactNavigation.popViewController(...)。
//     本示例不依赖这类混用调用的副作用；不把它们一概解释为有保证的“无操作”。
//
// MARK: - 12. 展开时：改变列的可见性，不是导航栈的 push / pop
//
// 普通列规则：
//   show(.secondary)、hide(.secondary)  → 都忽略；详情是展开布局的基础内容。
//   show(已可见的侧栏)                  → 不操作。
//   hide(已隐藏的侧栏)                  → 不操作。
//   其余侧栏请求                        → 转到该列可见 / 隐藏的最近可用 DisplayMode。
// 请求隐藏一列时，其他列也可能随显示模式一起变化，并非每列都能独立开关。
//
// 以下使用 tripleColumn + tile，并假设空间足够（P 分类 / S 列表 / D 详情）：
//
//   [P] [S] [D]  -- hide(.primary) ------>     [S] [D]
//   twoBesideSecondary                        oneBesideSecondary
//                                                    |
//                                           hide(.supplementary)
//                                                    v
//                                               [    D    ]
//                                               secondaryOnly
//                                                    |
//                                           show(.supplementary)
//                                                    v
//   [P] [S] [D]  <-- show(.primary) ------     [S] [D]
//
// overlay / displace 也遵循“找最近的可用模式”，但不能套用上图的并排外观。
// 图中的 secondaryOnly 仍是展开状态；hide(.primary) 不等于把整个 split 折叠。
//
// 点击流程：
//   点击分类 C → 更新 S 的列表、清除不属于 C 的旧文章 → show(.supplementary)。
//   点击文章 A → 更新 D 的正文 → show(.secondary) 在展开时不改变列布局。
//   如果产品要求“点文章后收起侧栏专心阅读”，应另行 hide(.supplementary)，
//   或明确设置 preferredDisplayMode = .secondaryOnly；这属于额外的布局策略。
//   详情中的“返回列表” → show(.supplementary)，让列表可见；详情仍然存在。
//   列表中的“返回分类” → show(.primary)，让分类可见；不是把详情页 pop 掉。
//
// 不要把 hide(.secondary) 写成通用“返回列表”：展开时它被忽略。
// 系统侧栏按钮即使画成返回箭头，也可能只是在改变 DisplayMode；不要仅凭图标判断 pop。
//
// MARK: - 13. 默认折叠时：show 可以前进，也可以返回
//
// 以下 [P, S, D] 表示列级导航的概念顺序，最右端是当前顶部，不是内部数组结构。
// 每列内部若又 push 了编辑页等控制器，则还有列内导航；本图只讨论列边界。
//
// show(column) 的三条规则：
//   目标不在当前列导航栈中 → 推入目标及所需的中间列。
//   目标就是顶部         → 不操作，不会重复添加同一列。
//   目标已在栈中但被覆盖 → 弹出覆盖它的列，回到目标。
//
//   [P 分类] --点击分类 C，更新列表 + show(.supplementary)--> [P, S 列表 C]
//   [P, S]  --点击文章 A，更新详情 + show(.secondary)------> [P, S, D 文章 A]
//   [P,S,D] --返回列表：show(.supplementary)---------------> [P, S]
//   [P, S]  --返回分类：show(.primary)--------------------> [P]
//
//   [P]     --show(.secondary)---------------------------> [P, S, D]
//              中间 S 也可能被加入；应先准备好分类 / 列表 / 文章数据。
//   [P,S,D] --show(.secondary)---------------------------> [P, S, D] 不重复入栈
//   [P,S,D] --show(.primary)-----------------------------> [P] 直接返回分类
//
// hide(column) 的规则比 show 更窄：
//   hide(.primary)                 → 始终忽略，不能把根列弹掉。
//   hide(非顶部列)                 → 忽略，不会从中间抽掉它，也不会替你弹出顶部。
//   hide(当前顶部的 S 或 D)        → 弹出该列，露出前一列。
//
//   [P,S,D] --hide(.secondary)-----> [P,S]    D 正在顶部，可以返回。
//   [P,S,D] --hide(.supplementary)-> [P,S,D]  S 不在顶部，忽略。
//   [P,S]   --hide(.supplementary)-> [P]      S 正在顶部，可以返回。
//   [P]     --hide(.primary)-------> [P]      根列，忽略。
//
// 因此，业务事件“返回列表”通常更适合表达为 show(.supplementary)：
// 它描述目标列，在默认折叠与展开时都具有合理含义。
// hide(.secondary) 则描述“关闭当前顶部详情列”，必须满足默认折叠的条件。
// 折叠界面的系统返回按钮可完成相应返回，不要在一次点击中再重复调用 hide / pop。
//
// MARK: - 14. 独立 compact：点击和返回由自己的 UINavigationController 处理
//
// split 已配置普通 P / S / D，同时 setViewController(compactNavigation, for: .compact)。
// 折叠后，屏幕上的三个业务页面是 compact 导航栈自己的页面实例：
//
//   [compact 分类]
//         | 点击分类 C：更新共享选择，push 自己的列表页
//         v
//   [compact 分类, compact 列表 C]
//         | 点击文章 A：更新共享选择，push 自己的详情页
//         v
//   [compact 分类, compact 列表 C, compact 详情 A]
//         | 系统返回按钮 / 返回手势 / popViewController(animated:)
//         v
//   [compact 分类, compact 列表 C]
//         | 再次返回 / popToRootViewController(animated:)
//         v
//   [compact 分类]
//
// 这里 push / pop 的不是 split 普通列中的控制器；不得把一个实例同时交给两个父容器。
// 如果要“回到指定页面”而非只退一级，用 popToViewController，而不是连续猜测 pop 次数。
// UIKit 不会因为 compact 页面标题叫“详情”，就把 hide(.secondary) 映射到它。
// 上一节 AdaptiveArticleSplit 用 setViewControllers 重建整个 compact 路由以简化示例；
// 以下补充代码在已有栈内返回，不重新创建页面，保留这些页面已有的 UI 状态。
//
// MARK: - 15. 给上一节示例补上返回与收起侧栏（最低 iOS 15）
//
// 将此 extension 与上面的 AdaptiveArticleSplit 放在同一个 Swift 文件中，
// 才能访问它的 private 成员；去掉每行最外层“// ”后即可使用。
// 代码处理稳定状态下的按钮事件；不要在折叠 / 展开动画中连续发起导航请求。
// compact 栈形状沿用上一例：[分类, 可选列表, 可选详情]，没有额外的编辑页。
// 若在真实项目加入更多页面，应保存对应控制器引用或路由标识，不依赖固定下标。
//
// BEGIN_SHOW_HIDE_EXAMPLE
// extension AdaptiveArticleSplit {
//     // 两种折叠方案公用的按钮事件；展开时含义是“重新显示列表栏”。
//     func returnToArticleList() {
//         guard selectedCategoryID != nil else { returnToCategories(); return }
//         if isCollapsed && usesCompactInterface {
//             let pages = compactNavigation.viewControllers
//             guard pages.count >= 2 else { return }
//             compactNavigation.popToViewController(pages[1], animated: true)
//         } else {
//             // 默认折叠：[P,S,D] → [P,S]；展开：让 S 可见，D 保留。
//             show(.supplementary)
//         }
//     }
//
//     func returnToCategories() {
//         if isCollapsed && usesCompactInterface {
//             compactNavigation.popToRootViewController(animated: true)
//         } else {
//             // 默认折叠：回到 P；展开：显示 P，布局由当前 SplitBehavior 决定。
//             show(.primary)
//         }
//     }
//
//     // “返回列表”与“清除文章选择”是两件事；本例返回时仍保留选中文章。
//     // 若用户点击“取消选择”，才显式清空 selectedArticleID 并刷新页面。
//     // 系统返回按钮和交互式返回手势也不会自动修改 App 的业务模型。
//
//     func focusOnArticleWhenExpanded() {
//         guard !isCollapsed, selectedArticleID != nil else { return }
//         // 普通三栏模式中，隐藏 S 会请求转到 secondaryOnly，P 也一起隐藏。
//         // hide(.secondary) 无法表达“只看详情”；它在展开状态下会被忽略。
//         hide(.supplementary)
//     }
//
//     // 仅供“默认折叠且详情列确在顶部”的列级关闭按钮调用。
//     func closeTopDetailColumnInDefaultCollapse() {
//         guard isCollapsed, !usesCompactInterface else { return }
//         // D 不在顶部时 UIKit 会忽略请求；不从 selectedArticleID 推断可见性。
//         hide(.secondary)
//     }
// }
// END_SHOW_HIDE_EXAMPLE
//
// 分类按钮：split.selectCategory("UIKit")  // 见上一例，先更新数据再进入列表。
// 文章按钮：split.selectArticle("A")       // 见上一例，先更新数据再进入详情。
// 返回列表：split.returnToArticleList()
// 返回分类：split.returnToCategories()
// 专心阅读：split.focusOnArticleWhenExpanded()
//
// 注意上一例折叠策略仍是“有选中文章就优先显示文章”。如果先返回分类但保留了选中 A，
// 再展开后重新折叠，代理仍可能把 A 放在顶部；这不代表 show / hide 的返回失败。
// 若产品要求重现返回后的当前位置，应单独记录 route = categories / list / article，
// 并让折叠代理与 compact 路由恢复读取 route，而不是仅用 selectedArticleID 判断。
// 对系统返回按钮与手势，要在导航完成的 didShow 等通知中更新路由；手势取消时不能提前提交。
//
// API 依据：Apple SDK UISplitViewController.h 中 showColumn: / hideColumn: 的分状态说明。
// 在线概览说明 show / hide 根据请求调整显示模式；详细折叠规则以上述 SDK 注释为依据。
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/show(_:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/hide(_:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller
//
// MARK: - 16. 选中文章是“内容状态”，route 是“已经到达的位置”
//
// 本节提供一个新的、可独立使用的 RouteReadingSplit 示例，替代前面按文章 ID 决定落点的策略。
// 前面的 AdaptiveArticleSplit 仍用于解释 API；不要同时安装两套导航代理或混用它们的状态。
//
//   selectedCategory / categoryID：当前业务分类，例如 UIKit。
//   selectedArticle / articleID：当前选中的文章，例如文章 A，可以在返回后继续保留。
//   route：最后一次完成导航后的层级，categories / list / detail。
//
//   操作                         选中文章         route           窄屏实际顶部
//   点击 UIKit 分类              nil              list            列表
//   点击文章 A，导航完成         A                detail          详情 A
//   系统返回，导航完成           A（保留）        list            列表
//   再次返回，导航完成           A（仍保留）      categories      分类
//
// “返回列表”只改变位置，不必清除选中 A；“切换到另一分类”才可能让 A 的选择失效。
// 示例的策略是：更换分类清除旧文章；返回和再次打开同一分类保留文章选择。
// 这是产品策略，不是 UIKit 自动替你作出的决定。
//
//   一个状态快照：categoryID = UIKit，articleID = A，route = list
//                 |                      |               |
//                 v                      v               v
//              列表的数据源           保留文章内容     折叠时先看列表
//
// 展开时三个页面可以同时可见，所以 route 不等于“屏幕唯一可见的列”。
// 本例把宽屏 route 定义为“最近明确进入的业务层级”，也是下次折叠时的恢复位置。
// 侧栏显示 / 隐藏、详情重新出现、布局变化，都不自动改写这个业务位置。
// 数据失效时先校正状态：无分类 → categories；要求 detail 但无文章 → list。
// 实际项目还应验证文章确实属于当前分类、是否已删除、是否仍有权限访问。
//
// MARK: - 17. 系统返回按钮、返回手势完成与取消：什么时候提交 route
//
// 起点：[分类, 列表, 详情 A]，articleID = A，route = detail。
//
//   系统 Back 按钮 / 边缘返回手势
//                  |
//                  v
//   willShow(列表)：这是待显示目标，尚不能认定已经返回
//                  |  route 仍为 detail
//          +-------+--------------------+
//          |                            |
//   按钮返回完成 / 手势完成          手势取消，回弹到详情
//          |                            |
//   实际顶部变成列表                实际顶部仍是详情 A
//          |                            |
//   didShow(列表)                   didShow(详情 A)，按实际显示结果处理
//          |                            |
//   route = list                    route = detail（幂等，保持不变）
//   articleID 仍为 A                articleID 仍为 A
//
// 不在 willShow、viewWillDisappear 或手势刚开始时把 route 改成 list，
// 否则手势取消时必须额外回滚，还可能把错误位置写进恢复状态。
// 本例采用“结果提交”：在 didShow 中识别实际显示的页面，再写 route。
// notifyWhenInteractionChanges 可读 context.isCancelled；本例只用它输出完成 / 取消提示。
// 该回调表示交互阶段改变，后续完成或回弹动画可能尚未结束，不把它当作页面已经切换。
// 不自行替换 interactivePopGestureRecognizer.delegate，不拦截系统 Back 按钮，
// 不重复执行一次 pop；由系统导航控制器驱动，再观察其结果。
//
// MARK: - 18. 折叠 / 展开恢复：内容与位置分别恢复
//
//   窄屏已返回列表：       [分类, 列表]       state = { UIKit, A, list }
//                             |
//                       窗口展开，返回 .twoBesideSecondary
//                             v
//   宽屏：                [分类] [列表] [详情 A]
//                          内容从共享状态更新；route 仍是 list
//                             |
//                       窗口再次折叠，按 route 重建 compact 栈
//                             v
//   窄屏：                [分类, 列表]       仍停在列表，不自动跳回文章 A
//
//   route = categories → compact 栈 [分类]
//   route = list       → compact 栈 [分类, 列表]
//   route = detail     → compact 栈 [分类, 列表, 详情]
//
// 恢复栈时设置 restoringStack，防止程序恢复产生的 didShow 反过来覆盖业务状态。
// split 转换期间设置 adaptingSplit，避免把布局调整误认作用户导航。
// 本例以最后提交的 route 为恢复依据；只在稳定界面接受新的点击导航请求。
// 不根据各列的 viewDidAppear 顺序更新 route：展开时多个列都可能出现。
// 本例覆盖同一控制器存活期间的宽窄切换，不包含进程退出后的持久化恢复；
// 如需后者，应保存 ReadingState 的数据字段，重建时校验 ID，再通过初始化参数传入。
//
// 【与 UIKit 默认折叠方案的关系】
// route 模型也适用于没有配置独立 .compact 的方案，折叠决策可以按位置返回：
//   switch state.route {
//   case .categories: return .primary
//   case .list:       return .supplementary
//   case .detail:     return .secondary
//   }
// 默认折叠时，业务返回请求仍可使用 show(.supplementary) / show(.primary)。
// 但不能把 UIKit 管理的列级导航结构当作自有 compactNavigation，
// 也不能假设给某一列的导航控制器设置 delegate 就能收到所有跨列返回事件。
// 需要观察默认折叠返回时，应结合实际容器的页面 / 转场完成通知确认目标及取消结果，
// 并排除展开、遮盖和列内导航；不依赖私有容器、固定数组下标或猜测栈结构。
// 下面第 19 节使用独立 compact；不设置 compact 的完整实现见第 20～23 节。
//
// MARK: - 19. 可点击的 route 示例（最低 iOS 15，独立 compact）
//
// 去掉每行最外层“// ”后，将完整代码放进一个新的 Swift 文件。
// 它与前面的 AdaptiveArticleSplit 是两个独立示例，不需要复制前面的 extension。
// 三栏和 compact 使用不同页面实例；compact 的页面实例在恢复时复用。
// 窄屏使用系统返回按钮和默认边缘返回手势，宽屏提供“返回列表 / 返回分类”业务按钮。
// 示例使用 UIKit 默认导航转场，不实现自定义交互转场；记录导航层级，不记录正文滚动位置。
//
// BEGIN_ROUTE_EXAMPLE
// import UIKit
//
// // 位置不携带文章 ID；位置与选择各自表达一件事。
// enum ReadingRoute: String {
//     case categories, list, detail
// }
//
// struct ReadingState {
//     var categoryID: String?
//     var articleID: String?
//     var route: ReadingRoute = .categories
//
//     // 恢复前修正无效组合：没有分类不能显示列表，没有文章不能显示详情。
//     mutating func normalize() {
//         if categoryID == nil {
//             articleID = nil
//             route = .categories
//         } else if route == .detail && articleID == nil {
//             route = .list
//         }
//     }
// }
//
// // 简单的可点击页面：分类、文章列表、文章详情共用这个页面类型。
// // 普通三栏与 compact 分别创建实例，只共享 ReadingState 的数据快照。
// @MainActor
// final class ReadingPage: UITableViewController {
//     let position: ReadingRoute
//     var onChoose: ((String) -> Void)?
//     var onBack: (() -> Void)?
//     private var rows: [String] = []
//
//     init(_ position: ReadingRoute) {
//         self.position = position
//         super.init(style: .insetGrouped)
//     }
//     required init?(coder: NSCoder) { fatalError("请使用代码初始化") }
//
//     func render(_ state: ReadingState) {
//         switch position {
//         case .categories:
//             title = "分类"
//             rows = ["UIKit", "Swift"]
//         case .list:
//             title = state.categoryID.map { "\($0) 文章列表" } ?? "请选择分类"
//             rows = state.categoryID == nil ? [] : ["文章 A", "文章 B"]
//         case .detail:
//             title = state.articleID ?? "请选择文章"
//             rows = ["选中：\(state.articleID ?? "无")", "已提交位置：\(state.route.rawValue)"]
//         }
//         if isViewLoaded { tableView.reloadData() }
//     }
//
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         // 只有宽屏普通列提供业务返回按钮；compact 保留系统 Back 按钮和默认返回手势。
//         if onBack != nil {
//             navigationItem.leftBarButtonItem = UIBarButtonItem(
//                 title: position == .detail ? "返回列表" : "返回分类",
//                 style: .plain, target: self, action: #selector(goBack))
//         }
//     }
//     @objc private func goBack() { onBack?() }
//     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//         rows.count
//     }
//     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//         let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
//         cell.textLabel?.text = rows[indexPath.row]
//         cell.accessoryType = position == .detail ? .none : .disclosureIndicator
//         return cell
//     }
//     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//         tableView.deselectRow(at: indexPath, animated: true)
//         guard position != .detail else { return }
//         onChoose?(rows[indexPath.row])
//     }
// }
//
// @MainActor
// final class RouteReadingSplit: UISplitViewController,
//     UISplitViewControllerDelegate, UINavigationControllerDelegate {
//     private(set) var state: ReadingState
//     private let compactNavigation = UINavigationController()
//     private let wideCategories = ReadingPage(.categories)
//     private let wideList = ReadingPage(.list)
//     private let wideDetail = ReadingPage(.detail)
//     private let compactCategories = ReadingPage(.categories)
//     private let compactList = ReadingPage(.list)
//     private let compactDetail = ReadingPage(.detail)
//     private var restoringStack = false
//     private var adaptingSplit = false
//
//     init(state: ReadingState = ReadingState()) {
//         var initial = state
//         initial.normalize()
//         self.state = initial
//         super.init(style: .tripleColumn)
//         delegate = self
//         compactNavigation.delegate = self // 自己持有的导航控制器；不要另设代理覆盖它。
//         preferredSplitBehavior = .tile
//         preferredDisplayMode = .twoBesideSecondary
//         minimumPrimaryColumnWidth = 200
//         maximumPrimaryColumnWidth = 320
//         preferredPrimaryColumnWidth = 240
//         minimumSupplementaryColumnWidth = 240
//         maximumSupplementaryColumnWidth = 380
//         preferredSupplementaryColumnWidth = 280
//
//         for page in [wideCategories, compactCategories] {
//             page.onChoose = { [weak self] id in self?.chooseCategory(id) }
//         }
//         for page in [wideList, compactList] {
//             page.onChoose = { [weak self] id in self?.chooseArticle(id) }
//         }
//         wideList.onBack = { [weak self] in self?.navigate(to: .categories) }
//         wideDetail.onBack = { [weak self] in self?.navigate(to: .list) }
//         setViewController(UINavigationController(rootViewController: wideCategories), for: .primary)
//         setViewController(UINavigationController(rootViewController: wideList), for: .supplementary)
//         setViewController(UINavigationController(rootViewController: wideDetail), for: .secondary)
//         refreshPages()
//         restoreCompactStack() // 启动即为窄屏时也有正确内容，不依赖某次折叠回调。
//         setViewController(compactNavigation, for: .compact)
//     }
//     required init?(coder: NSCoder) { fatalError("请使用代码初始化") }
//
//     private var canNavigate: Bool {
//         !adaptingSplit && !restoringStack && compactNavigation.transitionCoordinator == nil
//     }
//     private func chooseCategory(_ id: String) {
//         guard canNavigate else { return }
//         if state.categoryID != id { state.articleID = nil }
//         state.categoryID = id
//         refreshPages()
//         navigate(to: .list)
//     }
//     private func chooseArticle(_ id: String) {
//         guard canNavigate, state.categoryID != nil else { return }
//         state.articleID = id
//         refreshPages()
//         navigate(to: .detail)
//     }
//
//     // 这是“请求前往的位置”，compact 动画尚未完成时不立即提交 state.route。
//     private func navigate(to requested: ReadingRoute) {
//         guard canNavigate else { return }
//         var destination = state
//         destination.route = requested
//         destination.normalize()
//         let target = destination.route
//         if isCollapsed {
//             let page = compactPage(for: target)
//             if compactNavigation.topViewController === page { return }
//             if compactNavigation.viewControllers.contains(where: { $0 === page }) {
//                 compactNavigation.popToViewController(page, animated: true)
//             } else {
//                 // 此示例只从分类点击进入列表、从列表点击进入详情，不处理跨级深链跳转。
//                 compactNavigation.pushViewController(page, animated: true)
//             }
//             // route 留给 didShow 按实际显示页面提交；这里不把请求当成已完成的结果。
//         } else {
//             // 宽屏三列同时存在，route 表示最近明确进入的业务层级 / 下次折叠的落点。
//             state.route = target
//             refreshPages()
//             switch target {
//             case .categories: show(.primary)
//             case .list: show(.supplementary)
//             case .detail: break // 已更新详情；不通过隐藏侧栏改变业务 route。
//             }
//         }
//     }
//
//     private func compactPage(for route: ReadingRoute) -> ReadingPage {
//         switch route {
//         case .categories: return compactCategories
//         case .list: return compactList
//         case .detail: return compactDetail
//         }
//     }
//     private func refreshPages() {
//         for page in [wideCategories, wideList, wideDetail,
//                      compactCategories, compactList, compactDetail] { page.render(state) }
//     }
//     private func restoreCompactStack() {
//         state.normalize()
//         var stack: [UIViewController] = [compactCategories]
//         if state.route != .categories { stack.append(compactList) }
//         if state.route == .detail { stack.append(compactDetail) }
//         // 复用 compact 自己的实例；保持 route，抑制恢复操作产生的 didShow 回写。
//         restoringStack = true
//         compactNavigation.setViewControllers(stack, animated: false)
//         restoringStack = false
//     }
//
//     func navigationController(_ navigationController: UINavigationController,
//                               willShow viewController: UIViewController, animated: Bool) {
//         guard navigationController === compactNavigation,
//               !restoringStack, !adaptingSplit, isCollapsed else { return }
//         // 手势开始时 willShow 可能给出列表，但用户可以取消，因此这里绝不写 route。
//         navigationController.transitionCoordinator?.notifyWhenInteractionChanges { context in
//             // 此时手势阶段结束，后续完成 / 回弹动画可能仍在进行；这里只演示读取结果。
//             print(context.isCancelled ? "返回手势取消：保留原位置" : "返回手势完成：等待 didShow")
//         }
//     }
//
//     func navigationController(_ navigationController: UINavigationController,
//                               didShow viewController: UIViewController, animated: Bool) {
//         guard navigationController === compactNavigation,
//               !restoringStack, !adaptingSplit, isCollapsed,
//               navigationController.topViewController === viewController,
//               let page = viewController as? ReadingPage else { return }
//         // 系统 Back 按钮、交互式返回、程序化 push/pop，都归一到实际显示的页面。
//         // 取消返回后实际仍显示 detail，提交 detail 是幂等的；不会错误保存成 list。
//         state.route = page.position
//         state.normalize()
//         refreshPages()
//         print("已提交 route = \(state.route.rawValue)，文章 = \(state.articleID ?? "无")")
//     }
//
//     func splitViewController(_ svc: UISplitViewController,
//         topColumnForCollapsingToProposedTopColumn proposedTopColumn: Column) -> Column {
//         adaptingSplit = true
//         restoreCompactStack() // 按 route 恢复，而不是“只要有文章 ID 就进入详情”。
//         refreshPages()
//         return .compact
//     }
//     func splitViewController(_ svc: UISplitViewController,
//         displayModeForExpandingToProposedDisplayMode proposedDisplayMode: DisplayMode) -> DisplayMode {
//         adaptingSplit = true
//         // 三栏可以展示保留的文章 A，但不会因为详情重新可见就把 route 改成 detail。
//         refreshPages()
//         return .twoBesideSecondary
//     }
//     func splitViewControllerDidCollapse(_ svc: UISplitViewController) { adaptingSplit = false }
//     func splitViewControllerDidExpand(_ svc: UISplitViewController) { adaptingSplit = false }
// }
// END_ROUTE_EXAMPLE
//
// SceneDelegate 中完成 window 创建后，将它作为根控制器：
//   window.rootViewController = RouteReadingSplit()
//   window.makeKeyAndVisible()
// 恢复一个“文章 A 仍选中、当前位置在列表”的快照：
//   let saved = ReadingState(categoryID: "UIKit", articleID: "文章 A", route: .list)
//   window.rootViewController = RouteReadingSplit(state: saved)
//
// 【手动验证路径与预期；这些是验证步骤，不代表已运行 UI 测试】
// 1. 在窄屏依次点击 UIKit、文章 A：didShow 后 route 为 detail，文章为 A。
// 2. 点击系统返回按钮：route 为 list，文章仍为 A；再返回则 route 为 categories。
// 3. 重新进入文章 A，从左边缘缓慢拖动并取消：回弹后 route 仍为 detail。
// 4. 再次边缘拖动并完成返回：route 为 list，文章仍为 A。
// 5. 在 route = list 时扩大窗口，确认三栏含 A；再缩窄，确认顶部仍是列表。
// 6. 分别在 categories / detail 重复宽窄切换，确认恢复各自对应的 compact 栈。
// 7. 切换到 Swift 分类，确认旧文章清除；再次选择文章后确认 route 正常前进。
// 实测时还应覆盖导航动画与窗口调整重叠、快速重复点击、后台恢复等边界；
// 本教学代码不把类型检查等同于这些运行时场景已经验收。
//
// 官方回调语义：
// https://developer.apple.com/documentation/uikit/uinavigationcontrollerdelegate/navigationcontroller(_:didshow:animated:)
// https://developer.apple.com/documentation/uikit/uinavigationcontrollerdelegate/navigationcontroller(_:willshow:animated:)
// https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinator/notifywheninteractionchanges(_:)
// https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinatorcontext/iscancelled
//
// MARK: - 20. 手势与布局交错：页面凭证可以过期，导航结果不能丢
//
// 不设置独立 .compact，仍由 UIKit 组织默认折叠导航。App 观察自己的业务页面和公开转场回调。
// 上一版用 generation 丢弃全部旧回调，能避免布局污染，却遗漏了“已开始导航的最终结果”。
// 本版分成两种记录：
//   页面出现凭证：记录 layoutVersion；布局改变后作废，防止宽屏出现顺序改写 route。
//   导航事务：记录 id、source、target；即使布局改变，仍接收这笔事务的最终完成 / 取消结果。
//
// 以下完成 / 取消规则以内容仍有效为前提；删除、分类变更的优先级见第 21.1 节。
// 示例：手势从详情 D 返回列表 S，起点 route=detail、articleID=A。
//   UIKit 最终完成返回（isCancelled=false） → route=list，articleID 仍为 A。
//   UIKit 最终取消返回（isCancelled=true）  → route=detail，articleID 仍为 A。
//   结果尚未确定                         → route 暂时保持 detail，不提前保存 list。
//
// 以 UIKit 转场 completion 的 isCancelled 为准，不按拖动距离、手指松开或当前窗口宽度猜结果。
// 宽窄切换可能使 UIKit 自行结束或取消交互；用户想完成不等于 UIKit 最终一定完成。
// notifyWhenInteractionChanges 表示交互阶段改变，后续动画可能尚未结束；业务结算仍等 completion。
//
// 不再用旧布局版本直接拒绝导航 completion。用 transactionID 防止重复或过期结果覆盖新导航。
// 这是一种应用层状态协调策略，不是 UIKit 提供了内置 route 属性。
// 本例范围：每列一个业务页面，系统默认导航转场，无列内编辑页、模态页或嵌套分页。
// 扩展这些页面时应扩展子路由与导航来源识别，不把任意 viewWillAppear 当作跨列返回。
//
// MARK: - 21. 两条时序：完成选目标，取消选起点；先后顺序不改变规则
//
// 【手势最终完成】
//   [P,S,D]，route=detail，开始返回 → 保存事务 #7 { source:detail, target:list }
//            |
//            +-- 手势仍在进行时，窗口展开 --> [P] [S] [D]
//            |     暂停页面观察，布局版本改变，事务 #7 继续等待
//            |
//            +-- completion(#7, isCancelled=false)
//                         |
//                         v
//                    route=list，articleID=A
//                         |
//                    等待所有布局转换完成
//                         |
//             +-----------+----------------+
//             |                            |
//          仍为宽屏                     已再次折叠
//     更新状态；保留三栏             show(.supplementary) 校正到 [P,S]
//     下次折叠返回 S                 校正期间不把页面回调当作新导航
//
// 【手势最终取消】
//   [P,S,D]，route=detail，开始返回 → 保存事务 #8 { source:detail, target:list }
//            |
//            +-- 窗口展开 / 又缩窄 --> 结果未定，折叠代理暂用已提交位置 D
//            |
//            +-- completion(#8, isCancelled=true)
//                         |
//                         v
//                    route=detail，articleID=A
//                         |
//                    等待布局转换完成
//                         |
//                若已折叠，show(.secondary) 确认恢复 D
//
// 三种交错顺序都遵循相同结算规则：
//   布局先结束 → 等导航结果 → 按最终 route 校正。
//   导航先结束 → 先保存最终 route → 等布局结束 → 校正。
//   展开又折叠 → 结果未知时暂用原 route → 结果晚到后再次校正。
// 不在布局回调中伪造“导航成功”，也不因为页面没有在窄屏 didAppear 就永久丢掉成功返回。
// 同一笔 completion 重复到达只结算一次；旧事务不能覆盖较新事务。
// 内容失效后，旧事务的结果只用于结束转场等待，不再用于恢复旧 source / target。
//
// MARK: - 21.1. 删除文章 / 切换分类：有效内容优先于旧手势结果
//
// “取消返回”只取消这次导航，不会撤销已经发生的删除或分类切换。
// 因此不能无条件把 source = detail 恢复回来，必须使用当前数据校验过的 route。
//
//   事件                         选择校正                         route 校正
//   删除正在看的文章 A           articleID=nil，分类仍有效        detail → list
//   在分类页时删除已选文章 A     articleID=nil                    categories 保持不变
//   当前分类也被删除             categoryID=nil，articleID=nil    → categories
//   明确切换到 Swift 分类        categoryID=Swift，articleID=nil  → 新分类 list
//   删除与当前选择无关的文章     当前选择保持                     保留正常导航结果
//
// 只检查 articleID 非 nil 不够，还必须检查“文章存在，并属于当前分类”。
// ReadingLibrary 统一校验初始化快照、删除、分类切换与数据源替换，不自动选择下一篇文章。
// 同一个文章 ID 在删除后重新出现在数据源里，也不会自动恢复已经清空的选择。
//
// 三种标识各司其职：
//   transactionID 识别是哪一笔导航，拒绝重复或过期结果。
//   layoutVersion 识别布局，防止页面出现顺序污染 route。
//   contentVersion 识别选择上下文，防止旧选择的导航结果 / 页面凭证恢复失效内容。
//
// 【删除 A，随后返回手势取消】
//   route=detail(A)，contentVersion=2
//       |
//   开始返回：事务 #7 保存 source=detail、target=list、contentVersion=2
//       |
//   删除事件到达：从数据源移除 A，清空 articleID
//       |          contentVersion=3，立即校正 route=list，立即清空旧正文
//       |          事务 #7 仍保留，等 UIKit 完成，不能此刻强行发起第二次 pop
//       v
//   旧 completion(#7, cancelled=true)
//       |
//       +-- id 匹配：结束等待
//       +-- 内容版本 2 != 3：不应用旧 source=detail
//       v
//   导航与布局都结束 → 若已折叠，show(.supplementary)；若展开，更新列表与空详情
//   最终：articleID=nil，route=list，而不是被旧回调“复活”的 detail(A)
//
// 【切换分类，旧返回完成 / 取消】
//   UIKit 分类的列表 --开始返回分类页--> 旧事务 { list → categories, version=4 }
//       |
//   外部操作切换到 Swift：清空旧文章，route=list，contentVersion=5
//       |
//   旧事务完成：categories 不能覆盖新的 Swift 列表意图
//   旧事务取消：旧 UIKit 列表也不能重新成为当前选择
//       |
//   转场结束后按当前状态呈现 [Swift 列表]；完成和取消两条路径都保留新分类
//
// 【布局过程中失效 / 恢复过程中再次失效】
//   正在展开 / 折叠 → 删除 A → 立即清空选择并改 route=list → 等布局完成再校正。
//   正在恢复 list   → 分类又被删除 → route=categories → 等当前恢复结束，再校正到 categories。
//   每次校正都读取最新状态，不把旧闭包捕获的文章 ID 重新赋给选择。
//
// 关键实现边界：
// 1. 普通点击导航可以用 canNavigate 防止重复动画；来自数据层的删除 / 失效事件不能被它丢弃。
// 2. 数据事件在主线程串行处理。本例容器是 @MainActor，后台结果先切回 MainActor 再调用事件接口。
// 3. 内容失效时立即修正模型和正文；等到转场结束的只是容器的 show / hide 操作。
// 4. 保留 pending 到 UIKit completion，旧结果“结束等待”与“获准修改 route”是两件事。
// 5. 页面出现凭证同时校验两种版本，即使旧 completion 已结束，也不能让旧 didAppear 改回 detail。
// 6. 渲染列表直接使用当前数据源，不能继续显示固定的 [A,B] 示例数组或缓存的 A 正文。
//
// 这些事件接口在第 22 节完整代码中可用：
//   split.articleWasDeleted("文章 A", in: "UIKit")
//   split.categoryWasSwitched(to: "Swift")
//   split.categoryWasDeleted("UIKit")
//   split.catalogWasReplaced(latestCatalog)
// latestCatalog 必须由数据层保证是当前有效快照；本例不实现服务器响应的版本排序。
// 异步正文已接入同一内容上下文，具体校验与响应乱序见下一节；路由测试与正文测试分别验证。
//
// MARK: - 21.2 异步正文：请求 ID + 内容版本，拒绝旧请求晚返回
//
// 三种状态分别回答三个问题：
//   library.categoryID / articleID：当前选择属于谁？删除或切换分类时立即校正。
//   ledger.route：用户当前在分类 / 列表 / 详情哪个位置？由导航结果决定。
//   body.state：当前选择的正文是 idle / loading / loaded / failed？由有效请求结果决定。
// 正文响应只改变第三项。用户已返回列表时正文可以加载完成，但不能重新选中 ID 或 show(.secondary)。
//
// 请求凭证 = { UUID 请求 ID, 分类 ID, 文章 ID, contentVersion }
// ┌─────────────────────┬───────────────────────────────────────────────────┐
// │ 字段                │ 解决的问题                                        │
// ├─────────────────────┼───────────────────────────────────────────────────┤
// │ 分类 ID + 文章 ID   │ 明确正文所属对象，防止不同分类复用文章 ID 时混淆。  │
// │ contentVersion      │ 本地选择 / 内容上下文的代次；A→B→A 也已进入新代次。│
// │ 请求 ID（UUID）     │ 同文章、同版本重复刷新时，只有最后一笔可提交。      │
// │ layoutVersion       │ 仅用于页面出现凭证；不用它判断正文是否过期。        │
// └─────────────────────┴───────────────────────────────────────────────────┘
// contentVersion 沿用 RouteLedger，在选择改变 / 失效时递增；不是服务器文章修订号或 ETag。
// 当前文章编辑后需要重载，可调用 reloadArticleBody()：即使上下文版本相同，新请求 ID 也会淘汰旧请求。
// 若要求验证服务端内容新旧，还需在服务层校验服务器 revision / ETag；本例不保证后端缓存的新鲜度。
//
// 【A 请求慢，切换 B 后 B 先返回】
//   用户 / 主线程              正文服务                  可提交请求 / 屏幕
//   选 A，version=1 ─── r1(A,v1) ───────────┐             r1 / loading(A)
//   选 B，version=2 ─── r2(B,v2) ───┐      │             r2 / loading(B)，清掉 A 正文
//   cancel(r1)                     │      │             只是节省工作，不能作为安全依据
//   收到 r2 正文 <─────────────────┘      │             ID 和上下文匹配 → loaded(B)
//   收到 r1 正文 <────────────────────────┘             r1 已失效 → 丢弃，仍显示 B
//   若 r1 返回的是错误 / 取消：同样丢弃，不能清空 B 的 loading 或弹出 A 的错误。
//
// 【同文章重试，不能只比较 articleID 或版本】
//   A,v1 请求 r1 ──────────────────────────────┐
//   点击重新加载：A,v1 请求 r2 ────────┐       │
//   r2 成功 → 新正文                  ↓       │
//   r1 晚到 → ID != 当前有效 ID ───────────────┘ → 丢弃
//   A→B→A 也一样：新 A 的版本、请求 ID 都不同，第一笔 A 不会因为文章 ID 相同而复活。
//
// 【返回手势 / 宽窄转换期间删除 A】
//   detail(A) + r1 正在加载 + 返回事务 pending
//       ↓ 删除 A（MainActor 同步处理，无 await）
//   articleID=nil；contentVersion++；route 校正为 list
//       ↓ refresh() → body.synchronize(context: nil)
//   activeRequest=nil；state=idle；取消 r1；旧正文立即消失
//       ├─ r1 晚返回：没有有效凭证 → 丢弃，不写 articleID，不写 route
//       ├─ 返回完成：旧内容版本不能覆盖 route=list
//       └─ 返回取消：也不能恢复已被删除的 A 详情
//   布局与导航全部结束后，按当前 route 恢复列表。
//
// 【切换分类】
//   UIKit / A / r1 → 切换 Swift → 清空 A，route=list，撤销 r1
//                                      ↓ 选择 Swift / C → r2
//   r1 晚到：分类 / 选择上下文已变 → 丢弃；r2 成功才显示 C 正文。
//   如果尚未选择 C，则保持空详情，不因 r1 返回而自动选择旧文章。
//
// 【仅返回 / 仅布局改变，文章仍有效】
//   detail(A) + r1 → 返回成功，route=list → 展开 / 再折叠 → r1 成功
//   选择与 contentVersion 没变 → 正文可以保存为 loaded(A)，route 仍是 list。
//   返回取消则 route=detail；正文按相同规则更新。不要在 viewWillDisappear 中无条件取消加载，
//   因为它可能只是在交互返回或列重排中暂时消失。
//
// 提交规则：所有响应先回到 MainActor，检查与写入之间不允许 await：
//   guard activeRequest?.id == request.id, context == request.context else { return }
//   通过后才结束当前 loading、更新正文 / 当前错误；未通过连 task=nil 都不能执行。
// 切换选择后先同步安装新凭证 / 清除旧凭证，再 cancel 旧 Task；UI 渲染读取当前 body.state。
// onChange 只渲染，不递归调用 refresh()、不重新发请求；相同 context 的 refresh() 不重复加载。
//
// Apple 说明 Task.cancel 是协作式取消：没有检查取消的函数仍可能正常执行完毕。
// https://developer.apple.com/documentation/swift/task/cancel()
// 因此取消是资源优化，提交凭证才负责正确性。下面的测试服务故意忽略取消来验证这一点。
// 默认 DemoArticleBodyLoader 用可取消延迟模拟网络；可用 URLSession 的 async API 替换协议实现。
// 本例不包含实际后端、鉴权或跨页面正文缓存；响应不能绕开 ArticleBodyCoordinator 直接写 label。
//
// MARK: - 22. 可复制的 iOS 15 完整代码：模型 + 默认三栏控制器
//
// 去掉下面每行最外层“// ”，放入同一个 Swift 文件即可；不依赖上一节的 compact 示例。
// 仓库将纯状态模型单独放在 Sources/RouteModel，方便通过 SwiftPM 测试交错顺序；
// UIKit 示例通过 import RouteModel 使用它，下面已合并为无额外模块依赖的版本。
// SceneDelegate：window.rootViewController = DefaultRouteSplit()。
// 首屏恢复：DefaultRouteSplit(state: DefaultReadingState(categoryID: "UIKit",
//                                                   articleID: "文章 A", route: .list))。
//
// 核心区别：
// - finishNavigation 按导航 id 接收最终结果；布局变化不丢结果，内容版本改变则不采用旧位置。
// - confirmStableRoute 同时检查 layoutVersion 和 contentVersion，拒绝旧布局 / 旧选择的出现凭证。
// - takeReconciliation 等导航与所有布局转换都结束后，才取出一次校正请求。
// - 恢复 show(column) 期间暂停观察，防止自己的校正又启动一笔业务导航。
// - DispatchQueue.main.async 只是退出当前 UIKit 回调栈；不是用延迟秒数猜测动画完成。
//
// BEGIN_DEFAULT_ROUTE_EXAMPLE
// import UIKit
//
// // 不依赖 UIKit：把“导航结果”和“布局回调顺序”分开测试。
// public enum ReadingPosition: String, Sendable {
//     case categories, list, detail
// }
//
// public struct RouteLedger {
//     public struct Navigation: Equatable, Sendable {
//         public let id: Int
//         public let source: ReadingPosition
//         public let target: ReadingPosition
//         public let layoutVersion: Int
//         public let contentVersion: Int
//     }
//     public private(set) var route: ReadingPosition
//     public private(set) var pending: Navigation?
//     public private(set) var layoutVersion = 0
//     public private(set) var contentVersion = 0
//     public private(set) var needsReconciliation = false
//     private var nextID = 0
//     private var layouts: Set<Int> = []
//     public var isChangingLayout: Bool { !layouts.isEmpty }
//     public init(route: ReadingPosition = .categories) { self.route = route }
//
//     // 只在稳定布局中开始一笔导航。请求期间继续保留 source，等待最终结果。
//     public mutating func beginNavigation(to target: ReadingPosition) -> Navigation? {
//         guard pending == nil, !isChangingLayout, !needsReconciliation, target != route else { return nil }
//         nextID += 1
//         let transaction = Navigation(id: nextID, source: route, target: target, layoutVersion: layoutVersion, contentVersion: contentVersion)
//         pending = transaction
//         return transaction
//     }
//
//     // 关键：不能因 layoutVersion 改变而丢弃这笔导航的最终结果。
//     // 用导航 id 检查归属；内容仍有效时完成选 target、取消选 source，失效时保留已校正位置。
//     @discardableResult
//     public mutating func finishNavigation(id: Int, cancelled: Bool) -> Bool {
//         guard let transaction = pending, transaction.id == id else { return false }
//         // 内容已失效时，仅结束旧转场的等待；不再应用旧 source / target。
//         if transaction.contentVersion == contentVersion {
//             route = cancelled ? transaction.source : transaction.target
//         } else {
//             needsReconciliation = true
//         }
//         pending = nil
//         if layoutVersion != transaction.layoutVersion { needsReconciliation = true }
//         return true
//     }
//
//     // correctedRoute 由最新 ReadingLibrary 校验。外部失效事件不能被 canNavigate 丢弃。
//     // 立即保存有效位置，但 pending 留到 UIKit 真正结束，防止转场中强行 show / pop。
//     public mutating func contentChanged(correctedRoute: ReadingPosition, reconcile: Bool = true) {
//         contentVersion += 1
//         route = correctedRoute
//         if reconcile || pending != nil { needsReconciliation = true }
//     }
//
//     public mutating func beginLayout() -> Int {
//         nextID += 1
//         layouts.insert(nextID)
//         layoutVersion += 1
//         if pending != nil { needsReconciliation = true }
//         return nextID
//     }
//     public mutating func endLayout(_ id: Int) {
//         guard layouts.remove(id) != nil else { return }
//         layoutVersion += 1
//     }
//
//     // 布局全部结束且导航结果已知，才能消费一次校正请求。
//     public mutating func takeReconciliation() -> ReadingPosition? {
//         guard pending == nil, !isChangingLayout, needsReconciliation else { return nil }
//         needsReconciliation = false
//         return route
//     }
//
//     // 稳定状态下，无动画页面确认或宽屏的明确业务选择。
//     @discardableResult
//     public mutating func confirmStableRoute(_ position: ReadingPosition, version: Int, contentVersion capturedContent: Int) -> Bool {
//         guard pending == nil, !isChangingLayout, !needsReconciliation,
//               version == layoutVersion, capturedContent == contentVersion else { return false }
//         route = position
//         return true
//     }
// }
//
// // 选择与当前数据源一同校验；不能只用 articleID != nil 判断详情有效。
// public struct ReadingLibrary {
//     public static let demoCatalog = ["UIKit": ["文章 A", "文章 B"], "Swift": ["Swift 文章 C", "Swift 文章 D"]]
//     public private(set) var catalog: [String: [String]]
//     public private(set) var categoryID: String?
//     public private(set) var articleID: String?
//     public var categoryIDs: [String] { catalog.keys.sorted(by: >) }
//     public var articleIDs: [String] { categoryID.flatMap { catalog[$0] } ?? [] }
//
//     public init(catalog: [String: [String]] = Self.demoCatalog,
//                 categoryID: String? = nil, articleID: String? = nil) {
//         self.catalog = catalog; self.categoryID = categoryID; self.articleID = articleID
//         normalizeSelection()
//     }
//     private mutating func normalizeSelection() {
//         guard let categoryID, catalog[categoryID] != nil else {
//             self.categoryID = nil; articleID = nil; return
//         }
//         if let articleID, !articleIDs.contains(articleID) { self.articleID = nil }
//     }
//     public func correctedRoute(_ route: ReadingPosition) -> ReadingPosition {
//         guard categoryID != nil else { return .categories }
//         if route == .detail && articleID == nil { return .list }
//         return route // 已在分类页时，删除所选文章不强行把人带到列表。
//     }
//     @discardableResult
//     public mutating func selectCategory(_ id: String) -> Bool {
//         guard catalog[id] != nil, categoryID != id else { return false }
//         categoryID = id; articleID = nil
//         return true
//     }
//     @discardableResult
//     public mutating func selectArticle(_ id: String) -> Bool {
//         guard articleIDs.contains(id), articleID != id else { return false }
//         articleID = id; return true
//     }
//     public mutating func deleteArticle(_ id: String, in category: String) {
//         catalog[category]?.removeAll { $0 == id }
//         normalizeSelection()
//     }
//     public mutating func deleteCategory(_ id: String) {
//         catalog.removeValue(forKey: id)
//         normalizeSelection()
//     }
//     public mutating func replaceCatalog(_ snapshot: [String: [String]]) {
//         catalog = snapshot
//         normalizeSelection() // 同 ID 重新出现不会自动恢复已清空的选择。
//     }
// }
//
// import Foundation
//
// // contentVersion 是本地内容上下文的代次，不是服务器 ETag，也不是 layoutVersion。
// public struct ArticleBodyContext: Equatable, Sendable {
//     public let categoryID: String
//     public let articleID: String
//     public let contentVersion: Int
//     public init(categoryID: String, articleID: String, contentVersion: Int) {
//         self.categoryID = categoryID; self.articleID = articleID; self.contentVersion = contentVersion
//     }
// }
//
// public struct ArticleBodyRequest: Equatable, Sendable {
//     public let id: UUID
//     public let context: ArticleBodyContext
//     public init(context: ArticleBodyContext) { id = UUID(); self.context = context }
// }
//
// public enum ArticleBodyState: Equatable, Sendable {
//     case idle
//     case loading(ArticleBodyRequest)
//     case loaded(ArticleBodyRequest, String)
//     case failed(ArticleBodyRequest, String)
// }
//
// public protocol ArticleBodyLoading: Sendable {
//     func load(_ request: ArticleBodyRequest) async throws -> String
// }
//
// // 可直接运行的异步演示服务；接入后端时替换此协议实现，不改变提交结果的校验规则。
// public struct DemoArticleBodyLoader: ArticleBodyLoading {
//     public init() {}
//     public func load(_ request: ArticleBodyRequest) async throws -> String {
//         try await Task.sleep(nanoseconds: 150_000_000) // iOS 15 可用。
//         return "正文：\(request.context.articleID)"
//     }
// }
//
// @MainActor
// public final class ArticleBodyCoordinator {
//     public private(set) var state: ArticleBodyState = .idle
//     public private(set) var context: ArticleBodyContext?
//     public private(set) var activeRequest: ArticleBodyRequest?
//     public var onChange: (() -> Void)?
//     // 诊断 / 测试接点：收到响应且已完成接收或丢弃；不驱动路由。
//     public var onResponseProcessed: ((ArticleBodyRequest, Bool) -> Void)?
//     private let loader: any ArticleBodyLoading
//     private var task: Task<Void, Never>?
//
//     public init(loader: any ArticleBodyLoading = DemoArticleBodyLoader()) { self.loader = loader }
//     deinit { task?.cancel() }
//
//     // 删除 / 分类切换时，同步传 nil；不能等转场完成或再派发一轮主队列才作废请求。
//     // route 与宽窄布局变化不改变 context，因此不会重复加载或清空仍然有效的正文。
//     public func synchronize(context newContext: ArticleBodyContext?) {
//         guard context != newContext else { return }
//         context = newContext
//         if newContext != nil { reload() }
//         else {
//             let oldTask = task
//             activeRequest = nil; task = nil; state = .idle
//             oldTask?.cancel() // 先撤销提交资格，再请求取消网络工作。
//             onChange?()
//         }
//     }
//
//     public func reload() {
//         guard let context else { return }
//         let request = ArticleBodyRequest(context: context) // 同文章重试也必须产生新 ID。
//         let oldTask = task
//         activeRequest = request
//         state = .loading(request) // 立即移除上一文章正文，禁止标题 B 配正文 A。
//         oldTask?.cancel()
//         let service = loader
//         task = Task { [weak self] in
//             // 不在 await 前强持有 self，避免长请求把页面状态永久留住。
//             let result: Result<String, Error>
//             do { result = .success(try await service.load(request)) }
//             catch { result = .failure(error) }
//             self?.receive(result, for: request)
//         }
//         onChange?()
//     }
//
//     private func receive(_ result: Result<String, Error>, for request: ArticleBodyRequest) {
//         // 所有成功、失败和取消都走同一扇门。检查与提交之间没有 await。
//         guard activeRequest?.id == request.id, context == request.context else {
//             onResponseProcessed?(request, false)
//             return // 旧回调不能清空新 task / spinner，也不能弹出旧错误。
//         }
//         activeRequest = nil; task = nil
//         switch result {
//         case .success(let body): state = .loaded(request, body)
//         case .failure(let error):
//             if error is CancellationError || (error as? URLError)?.code == .cancelled {
//                 state = .idle // 当前请求主动结束，用户可显式重试。
//             } else { state = .failed(request, error.localizedDescription) }
//         }
//         onChange?()
//         onResponseProcessed?(request, true)
//         // 不选中文章、不调用 show、不修改 route；正文到达并不代表用户重新进入详情。
//     }
// }
//
//
// typealias DefaultReadingRoute = ReadingPosition
// extension ReadingPosition {
//     var column: UISplitViewController.Column {
//         switch self {
//         case .categories: return .primary
//         case .list: return .supplementary
//         case .detail: return .secondary
//         }
//     }
// }
//
// struct DefaultReadingState {
//     var categoryID: String?
//     var articleID: String?
//     var route: DefaultReadingRoute = .categories
//     var categoryIDs: [String] = []
//     var articleIDs: [String] = []
//     var bodyState: ArticleBodyState = .idle
// }
//
// // 普通页面出现凭证受布局版本约束；导航事务的最终结果另按 transactionID 接收。
// @MainActor
// private final class AppearanceEvidence {
//     let version: Int
//     let contentVersion: Int
//     init(version: Int, contentVersion: Int) {
//         self.version = version; self.contentVersion = contentVersion
//     }
// }
//
// @MainActor
// private final class DefaultReadingPage: UITableViewController {
//     let position: DefaultReadingRoute
//     weak var owner: DefaultRouteSplit?
//     private var evidence: AppearanceEvidence?
//     private var rows: [String] = []
//     private var articleCount = 0
//
//     init(_ position: DefaultReadingRoute) {
//         self.position = position
//         super.init(style: .insetGrouped)
//     }
//     required init?(coder: NSCoder) { fatalError("使用代码初始化") }
//
//     func render(_ state: DefaultReadingState) {
//         switch position {
//         case .categories:
//             title = "分类"; rows = state.categoryIDs
//         case .list:
//             title = state.categoryID.map { "\($0) 列表" } ?? "请选择分类"
//             articleCount = state.articleIDs.count
//             rows = state.categoryID == nil ? [] : state.articleIDs + ["返回分类（业务操作）"]
//         case .detail:
//             title = state.articleID ?? "文章已删除或未选择"
//             let body: String
//             switch state.bodyState {
//             case .idle: body = "请选择文章或重新加载"
//             case .loading: body = "正在加载正文：\(state.articleID ?? "无")"
//             case .loaded(_, let text): body = text
//             case .failed(_, let message): body = "加载失败：\(message)"
//             }
//             rows = [body, "返回列表（业务操作）", "重新加载正文"]
//         }
//         // 方便观察 route；系统返回按钮由 UIKit 自己生成，不替换 leftBarButtonItem。
//         navigationItem.prompt = "route=\(state.route.rawValue) · article=\(state.articleID ?? "nil")"
//         if isViewLoaded { tableView.reloadData() }
//     }
//
//     override func viewWillAppear(_ animated: Bool) {
//         super.viewWillAppear(animated)
//         evidence = owner?.pageWillAppear(self, coordinator: transitionCoordinator)
//     }
//     override func viewDidAppear(_ animated: Bool) {
//         super.viewDidAppear(animated)
//         owner?.pageDidAppear(self, evidence: evidence)
//     }
//     override func viewWillDisappear(_ animated: Bool) {
//         super.viewWillDisappear(animated)
//         evidence = nil // 只作废页面出现证据，不作废正在等待结果的导航事务。
//     }
//
//     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//         rows.count
//     }
//     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//         let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
//         cell.textLabel?.text = rows[indexPath.row]
//         cell.accessibilityIdentifier = "\(position.rawValue).\(indexPath.row)"
//         return cell
//     }
//     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//         tableView.deselectRow(at: indexPath, animated: true)
//         guard rows.indices.contains(indexPath.row) else { return }
//         switch position {
//         case .categories: owner?.selectCategory(rows[indexPath.row])
//         case .list:
//             if indexPath.row < articleCount { owner?.selectArticle(rows[indexPath.row]) }
//             else { owner?.go(to: .categories) }
//         case .detail:
//             if indexPath.row == 1 { owner?.go(to: .list) }
//             if indexPath.row == 2 { owner?.reloadArticleBody() }
//         }
//     }
// }
//
// @MainActor
// final class DefaultRouteSplit: UISplitViewController, UISplitViewControllerDelegate {
//     private(set) var state: DefaultReadingState
//     private var ledger: RouteLedger
//     private var library: ReadingLibrary
//     private let body: ArticleBodyCoordinator
//     var onStateChange: ((String) -> Void)?
//     // 仅供验证外壳在真实交互转场开始后触发布局变化，不伪造导航结果。
//     var onInteractiveNavigationBegan: (() -> Void)?
//     var onInteractiveNavigationDecision: (() -> Void)?
//     var onColumnAdaptationBegan: (() -> Void)?
//     private let categories = DefaultReadingPage(.categories)
//     private let list = DefaultReadingPage(.list)
//     private let detail = DefaultReadingPage(.detail)
//     private var pages: [DefaultReadingPage] { [categories, list, detail] }
//     private var columnLayoutID: Int?
//     private var restoring = false
//     private var hasAppeared = false
//     private var reconciliationScheduled = false
//     private var navigationCoordinator: UIViewControllerTransitionCoordinator?
//     private var completionQueued = true
//     private var lastResult = "none"
//     private var overlaps = 0
//     private var cancellations = 0
//     private var invalidationsDuringNavigation = 0
//     private var invalidationsDuringLayout = 0
//     private var ignoredContentResults = 0
//     private var bodyResponses = 0
//
//     init(state: DefaultReadingState = DefaultReadingState(),
//          catalog: [String: [String]] = ReadingLibrary.demoCatalog,
//          bodyLoader: any ArticleBodyLoading = DemoArticleBodyLoader()) {
//         body = ArticleBodyCoordinator(loader: bodyLoader)
//         library = ReadingLibrary(catalog: catalog, categoryID: state.categoryID, articleID: state.articleID)
//         var initial = state
//         initial.route = library.correctedRoute(initial.route)
//         self.state = initial
//         ledger = RouteLedger(route: initial.route)
//         super.init(style: .tripleColumn)
//         delegate = self
//         preferredSplitBehavior = .tile
//         preferredDisplayMode = .twoBesideSecondary
//         minimumPrimaryColumnWidth = 200
//         maximumPrimaryColumnWidth = 320
//         preferredPrimaryColumnWidth = 240
//         minimumSupplementaryColumnWidth = 240
//         maximumSupplementaryColumnWidth = 380
//         preferredSupplementaryColumnWidth = 280
//         for page in pages {
//             page.owner = self
//             setViewController(UINavigationController(rootViewController: page), for: page.position.column)
//         }
//         body.onResponseProcessed = { [weak self] _, _ in
//             guard let self else { return }
//             self.bodyResponses += 1
//             self.publish()
//         }
//         body.onChange = { [weak self] in self?.renderBody() }
//         // 不设置 .compact；不接管列导航代理，也不替换系统 Back 和边缘返回手势。
//         refresh()
//     }
//     required init?(coder: NSCoder) { fatalError("使用代码初始化") }
//
//     private var canObserve: Bool {
//         hasAppeared && isCollapsed && !restoring && !ledger.isChangingLayout && !ledger.needsReconciliation
//     }
//     private var canNavigate: Bool {
//         hasAppeared && !restoring && !ledger.isChangingLayout && ledger.pending == nil &&
//         !ledger.needsReconciliation && transitionCoordinator == nil &&
//         pages.allSatisfy { $0.transitionCoordinator == nil }
//     }
//
//     fileprivate func pageWillAppear(_ page: DefaultReadingPage,
//         coordinator: UIViewControllerTransitionCoordinator?) -> AppearanceEvidence? {
//         guard canObserve, library.correctedRoute(page.position) == page.position else { return nil }
//         if let coordinator, let transaction = ledger.beginNavigation(to: page.position) {
//             // 捕获这笔真实导航的 source/target。布局版本改变后仍必须接收它的最终结果。
//             navigationCoordinator = coordinator
//             completionQueued = coordinator.animate(alongsideTransition: nil) { [weak self] context in
//                 self?.navigationFinished(id: transaction.id, cancelled: context.isCancelled)
//             }
//             if coordinator.initiallyInteractive {
//                 coordinator.notifyWhenInteractionChanges { [weak self] _ in
//                     self?.onInteractiveNavigationDecision?() // 验证接口，不在此提交 route。
//                 }
//                 onInteractiveNavigationBegan?()
//             }
//             return nil
//         }
//         guard ledger.pending == nil else { return nil }
//         return AppearanceEvidence(version: ledger.layoutVersion, contentVersion: ledger.contentVersion)
//     }
//
//     fileprivate func pageDidAppear(_ page: DefaultReadingPage, evidence: AppearanceEvidence?) {
//         // animate 返回 false 时完成块仍可能执行。若页面先完成出现，可按同一事务幂等结算。
//         if !completionQueued, let transaction = ledger.pending, let coordinator = navigationCoordinator,
//            !ledger.isChangingLayout, !restoring {
//             let expected = coordinator.isCancelled ? transaction.source : transaction.target
//             if page.position == expected {
//                 navigationFinished(id: transaction.id, cancelled: coordinator.isCancelled)
//             }
//         }
//         guard canObserve, let evidence, page.viewIfLoaded?.window != nil else { return }
//         // 无动画 / 普通页面确认只能在稳定布局中写入；过期版本或 pending 存在时模型会拒绝。
//         guard library.correctedRoute(page.position) == page.position else { return }
//         if ledger.confirmStableRoute(page.position, version: evidence.version,
//                                      contentVersion: evidence.contentVersion) { refresh() }
//     }
//
//     private func navigationFinished(id: Int, cancelled: Bool) {
//         // 不使用布局 generation 拒绝本回调；按 transactionID 校验，重复和过期结果无效。
//         let obsoleteContent = ledger.pending.map { $0.contentVersion != ledger.contentVersion } ?? false
//         guard ledger.finishNavigation(id: id, cancelled: cancelled) else { return }
//         if obsoleteContent { ignoredContentResults += 1 }
//         navigationCoordinator = nil
//         lastResult = cancelled ? "cancelled" : "completed"
//         if cancelled { cancellations += 1 }
//         refresh()
//         scheduleReconciliation()
//     }
//
//     fileprivate func selectCategory(_ id: String) {
//         guard canNavigate else { return }
//         guard library.categoryIDs.contains(id) else { return }
//         if library.selectCategory(id) {
//             ledger.contentChanged(correctedRoute: library.correctedRoute(ledger.route), reconcile: false)
//         }
//         refresh(); go(to: .list)
//     }
//     fileprivate func selectArticle(_ id: String) {
//         guard canNavigate, library.articleIDs.contains(id) else { return }
//         if library.selectArticle(id) {
//             ledger.contentChanged(correctedRoute: library.correctedRoute(ledger.route), reconcile: false)
//         }
//         refresh(); go(to: .detail)
//     }
//     fileprivate func go(to requested: DefaultReadingRoute) {
//         guard canNavigate else { return }
//         let destination = library.correctedRoute(requested)
//         if !isCollapsed {
//             ledger.confirmStableRoute(destination, version: ledger.layoutVersion,
//                                       contentVersion: ledger.contentVersion)
//             refresh() // 宽屏 route 由明确业务点击决定，不由各页出现顺序决定。
//         }
//         show(destination.column)
//     }
//     // 数据事件不能使用 canNavigate 过滤，否则动画期间发生的删除会丢失。
//     func articleWasDeleted(_ id: String, in category: String) {
//         updateCatalog { $0.deleteArticle(id, in: category) }
//     }
//     func categoryWasDeleted(_ id: String) {
//         updateCatalog { $0.deleteCategory(id) }
//     }
//     func catalogWasReplaced(_ snapshot: [String: [String]]) {
//         updateCatalog { $0.replaceCatalog(snapshot) }
//     }
//     func categoryWasSwitched(to id: String) {
//         guard library.selectCategory(id) else { return }
//         invalidateSelection(to: .list) // 明确的切换分类意图：进入新分类列表。
//     }
//     private func updateCatalog(_ update: (inout ReadingLibrary) -> Void) {
//         let oldCategory = library.categoryID
//         let oldArticle = library.articleID
//         update(&library)
//         if oldCategory != library.categoryID || oldArticle != library.articleID {
//             invalidateSelection(to: library.correctedRoute(ledger.route))
//         } else {
//             refresh() // 删除无关文章只刷新数据，不取消仍然有效的返回意图。
//         }
//     }
//     private func invalidateSelection(to route: ReadingPosition) {
//         if ledger.pending != nil { invalidationsDuringNavigation += 1 }
//         if ledger.isChangingLayout { invalidationsDuringLayout += 1 }
//         ledger.contentChanged(correctedRoute: library.correctedRoute(route))
//         // 立即清空旧正文；等待转场结束的是容器导航，而不是删除这件业务事实。
//         refresh()
//         scheduleReconciliation()
//     }
//     fileprivate func reloadArticleBody() { body.reload() }
//     // 正文更新只渲染；不会把 route=list 的用户重新带回详情。
//     private func renderBody() {
//         state.bodyState = body.state
//         pages.forEach { $0.render(state) }
//         publish()
//     }
//     private func refresh() {
//         state.categoryID = library.categoryID
//         state.articleID = library.articleID
//         state.categoryIDs = library.categoryIDs
//         state.articleIDs = library.articleIDs
//         state.route = ledger.route
//         let context: ArticleBodyContext?
//         if let category = library.categoryID, let article = library.articleID,
//            library.articleIDs.contains(article) {
//             context = ArticleBodyContext(categoryID: category, articleID: article,
//                                          contentVersion: ledger.contentVersion)
//         } else { context = nil }
//         body.synchronize(context: context)
//         renderBody()
//     }
//     private func publish() {
//         onStateChange?("route=\(ledger.route.rawValue) article=\(state.articleID ?? "nil") " +
//             "collapsed=\(isCollapsed) cancelled=\(cancellations) result=\(lastResult) " +
//             "pending=\(ledger.pending != nil) layout=\(ledger.isChangingLayout) " +
//             "restore=\(restoring) overlap=\(overlaps) category=\(state.categoryID ?? "nil") " +
//             "content=\(ledger.contentVersion) invalidNav=\(invalidationsDuringNavigation) " +
//             "invalidLayout=\(invalidationsDuringLayout) ignoredContent=\(ignoredContentResults) bodyResponses=\(bodyResponses)")
//     }
//
//     // 导航和布局都结束后，退出当前 UIKit 回调栈再做一次校正。不是固定延迟猜动画时间。
//     private func scheduleReconciliation() {
//         guard !reconciliationScheduled else { return }
//         reconciliationScheduled = true
//         DispatchQueue.main.async { [weak self] in
//             guard let self else { return }
//             self.reconciliationScheduled = false
//             guard !self.restoring, self.hasAppeared,
//                   let route = self.ledger.takeReconciliation() else { return }
//             if self.isCollapsed { self.restoreCollapsedRoute(route) }
//             else { self.refresh() } // 展开只同步数据，下次折叠使用最终 route。
//         }
//     }
//     private func restoreCollapsedRoute(_ route: ReadingPosition) {
//         restoring = true
//         let layout = ledger.beginLayout()
//         show(route.column) // 可能返回、前进或无需操作；不手工操作 UIKit 的内部导航栈。
//         if let coordinator = transitionCoordinator {
//             coordinator.animate(alongsideTransition: nil) { [weak self] _ in
//                 self?.finishRestoration(layout)
//             }
//         } else {
//             finishRestoration(layout)
//         }
//     }
//     private func finishRestoration(_ layout: Int) {
//         ledger.endLayout(layout)
//         restoring = false
//         refresh()
//         scheduleReconciliation()
//     }
//     private func beginLayout() -> Int {
//         if ledger.pending != nil { overlaps += 1 }
//         return ledger.beginLayout()
//     }
//     private func endLayout(_ id: Int) {
//         ledger.endLayout(id)
//         refresh()
//         scheduleReconciliation()
//     }
//     override func viewDidAppear(_ animated: Bool) {
//         super.viewDidAppear(animated)
//         guard !hasAppeared else { return }
//         hasAppeared = true
//         if isCollapsed { restoreCollapsedRoute(ledger.route) }
//         publish()
//     }
//     override func viewWillTransition(to size: CGSize,
//                                      with coordinator: UIViewControllerTransitionCoordinator) {
//         let layout = beginLayout()
//         super.viewWillTransition(to: size, with: coordinator)
//         coordinator.animate(alongsideTransition: nil) { [weak self] _ in self?.endLayout(layout) }
//     }
//     private func beginColumnAdaptation() {
//         if columnLayoutID == nil {
//             columnLayoutID = beginLayout()
//             onColumnAdaptationBegan?() // 测试可在真实布局转换开始后注入数据事件。
//         }
//     }
//     private func finishColumnAdaptation() {
//         guard let id = columnLayoutID else { return }
//         columnLayoutID = nil; endLayout(id)
//     }
//     func splitViewController(_ svc: UISplitViewController,
//         topColumnForCollapsingToProposedTopColumn proposedTopColumn: Column) -> Column {
//         beginColumnAdaptation()
//         // 结果未定时暂用最后提交的位置；若结果晚到，scheduleReconciliation 再校正。
//         return ledger.route.column
//     }
//     func splitViewController(_ svc: UISplitViewController,
//         displayModeForExpandingToProposedDisplayMode proposedDisplayMode: DisplayMode) -> DisplayMode {
//         beginColumnAdaptation(); return .twoBesideSecondary
//     }
//     func splitViewControllerDidCollapse(_ svc: UISplitViewController) { finishColumnAdaptation() }
//     func splitViewControllerDidExpand(_ svc: UISplitViewController) { finishColumnAdaptation() }
// }
// END_DEFAULT_ROUTE_EXAMPLE
//
// MARK: - 23. 交错场景测试：模型顺序与真实 UIKit 接线分别验证
//
// 完整模型测试：Tests/RouteModelTests/RouteLedgerTests.swift 与 ContentInvalidationTests.swift，运行 swift test。
// 完整 UI 测试：Examples/DefaultRouteHarness/TripleColumnDemoUITests/TripleColumnDemoUITests.swift。
// 打开示例的 TripleColumnDemo.xcworkspace，运行 TripleColumnDemo scheme 的测试。
//
// 模型测试验证以下顺序，每种关键顺序同时验证完成与取消：
//   返回开始 → 展开开始 → 展开结束 → 返回结果。
//   返回开始 → 展开开始 → 返回结果 → 展开结束。
//   返回开始 → 展开完成 → 再次折叠完成 → 返回结果晚到。
//   尺寸转换与列转换嵌套；全部结束前不能校正。
//   旧页面凭证、重复 completion、旧事务结果不得覆盖新位置。
//
// 导航完成 / 取消及内容失效的最小断言示例（XCTest 测试文件，不与 App 源码一起编译）：
// BEGIN_ROUTE_OVERLAP_TESTS
// import XCTest
// // 若在仓库测试目标中使用，再加：@testable import RouteModel
// final class RouteOverlapExampleTests: XCTestCase {
//     func testCompletedReturnAfterExpandAndCollapse() {
//         var state = RouteLedger(route: .detail)
//         let back = state.beginNavigation(to: .list)!
//         let wide = state.beginLayout()
//         state.endLayout(wide)
//         let narrow = state.beginLayout()
//         state.endLayout(narrow)
//         XCTAssertEqual(state.route, .detail) // 尚未确定，保留起点。
//         XCTAssertNil(state.takeReconciliation())
//         state.finishNavigation(id: back.id, cancelled: false)
//         XCTAssertEqual(state.route, .list) // 布局版本虽已改变，成功结果仍有效。
//         XCTAssertEqual(state.takeReconciliation(), .list)
//     }
//     func testCancelledReturnBeforeLayoutEnds() {
//         var state = RouteLedger(route: .detail)
//         let back = state.beginNavigation(to: .list)!
//         let wide = state.beginLayout()
//         state.finishNavigation(id: back.id, cancelled: true)
//         XCTAssertEqual(state.route, .detail)
//         XCTAssertNil(state.takeReconciliation()) // 导航结束，但布局尚未结束。
//         state.endLayout(wide)
//         XCTAssertEqual(state.takeReconciliation(), .detail)
//         XCTAssertFalse(state.finishNavigation(id: back.id, cancelled: false)) // 重复结果无效。
//     }
// }
//
// final class ContentInvalidationExampleTests: XCTestCase {
//     func testDeletionWinsOverCancelledReturn() {
//         var content = ReadingLibrary(categoryID: "UIKit", articleID: "文章 A")
//         var routes = RouteLedger(route: .detail)
//         let oldBack = routes.beginNavigation(to: .list)!
//         content.deleteArticle("文章 A", in: "UIKit")
//         routes.contentChanged(correctedRoute: content.correctedRoute(routes.route))
//         XCTAssertNil(content.articleID)
//         XCTAssertEqual(routes.route, .list)
//         XCTAssertNil(routes.takeReconciliation()) // 转场没完，先不操作容器。
//         routes.finishNavigation(id: oldBack.id, cancelled: true)
//         XCTAssertEqual(routes.takeReconciliation(), .list) // 取消不恢复已删除详情。
//     }
//     func testNewCategoryWinsOverOldSuccessfulReturn() {
//         var content = ReadingLibrary(categoryID: "UIKit", articleID: "文章 A")
//         var routes = RouteLedger(route: .list)
//         let oldBack = routes.beginNavigation(to: .categories)!
//         content.selectCategory("Swift")
//         routes.contentChanged(correctedRoute: content.correctedRoute(.list))
//         routes.finishNavigation(id: oldBack.id, cancelled: false)
//         XCTAssertEqual(content.categoryID, "Swift")
//         XCTAssertNil(content.articleID)
//         XCTAssertEqual(routes.takeReconciliation(), .list) // 新分类列表优先于旧 categories 目标。
//     }
// }
// END_ROUTE_OVERLAP_TESTS
//
// UI 测试使用系统边缘返回手势，未替换交互驱动器，也未直接调用模型伪造完成 / 取消：
// 1. 普通系统 Back + 列表 / 分类位置宽窄恢复，作为回归基线。
// 2. 普通交互式返回取消与完成，检查 route 与文章选择。
// 3. 手指仍在拖动期间，由验证外壳触发展开，检查实际最终结果及再次折叠的顶部页面。
// 4. 用户已作出“完成”决定，退出交互回调栈后、完成动画尚未结束时展开，检查 route=list。
// 5. 用户已作出“取消”决定，退出交互回调栈后、回弹动画尚未结束时展开，检查 route=detail。
// 6. 取消返回前删除 A：确认系统结果 cancelled，但 route=list、articleID=nil，旧正文消失。
// 7. 完成返回前删除 A 并展开：route=list，重新折叠后仍是有效列表。
// 8. 取消返回前切换到 Swift 并展开：新分类保留、旧文章清空，不能恢复 UIKit 的旧详情。
// 9. 手指拖动期间删除 A 并展开：无论系统最终完成或取消，均不能再呈现 A。
// 10. 真实列展开回调期间删除 A：数据事件不被 canNavigate 丢弃，布局结束后恢复列表。
//
// 内容用例检查 invalidNav / invalidLayout > 0，证明失效事件确实与导航 / 布局重叠；
// ignoredContent > 0 证明旧导航结果到达后只结束等待，没有覆盖校正后的 route。
// 还断言文章 A 的正文消失，列表使用最新数据，目标页面可点击。
// 模型另行覆盖当前分类删除、无关文章删除、同 ID 重新出现、恢复中二次失效和旧 didAppear。
//
// 测试外壳的 0.1 秒定时仅用于制造“手指拖动与布局变化重叠”，不是业务恢复逻辑。
// 第 3 项不能只断言“最后是列表”：环境变化可能让 UIKit 取消；必须验证 result 对应的 route。
// 同时检查 overlap>0，证明布局开始时导航事务仍未完成，避免把顺序操作误报为交错测试。
// 第 4、5 项分别断言真正的 completed / cancelled，不能用“自动接受任何结果”替代分支覆盖。
// UI 测试还断言再次折叠后目标页面可点击，不只检查状态字符串。
//
// 验证外壳通过公开容器宽度和尺寸类别切换触发布局，不等同于所有 Stage Manager / 分屏拖动路径。
// 不把模型测试通过等同于真实系统手势通过，也不把 iOS 15 编译检查等同于 iOS 15 运行时验证。
// 上一轮内容失效验证：17 项模型测试 + 10 项 iPadOS 27.0 UI 测试通过，0 失败、0 跳过。
// 从本文件提取的完整代码通过 iOS 15 部署目标类型检查；未执行 iOS 15 运行时验证。
// 上一轮 UI 工具连接曾在 300 秒超时；最终结果已从完成的 xcresult 读取并核对。
// 本轮实际通过：25 项模型测试；8 项 UI 测试（新增正文 4 项 + 导航回归 4 项），0 失败、0 跳过。
// 最后一次构建无 Swift 警告；具体测试列表与边界见 Verification/异步正文验证.md。
// 交错基础记录见 Verification/交错场景验证.md；本轮结果见 Verification/内容失效验证.md。
//
// 官方依据：
// https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinator/animate(alongsidetransition:completion:)
// https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinatorcontext/iscancelled
// https://developer.apple.com/documentation/uikit/uiviewcontrollertransitioncoordinator/notifywheninteractionchanges(_:)
//
// MARK: - 23.1 异步正文的可控乱序测试（独立 XCTest 文件）
//
// 以下为仓库实际执行的完整测试；App 仅复制第 22 节，测试目标单独加入此节。
// 独立复制合并示例时，将 @testable import RouteModel 改成自己的 App 模块名。
// nextRequest 等待服务真正收到请求，deliver 等待响应已提交或丢弃；不依赖固定延迟。
// import XCTest
// @testable import RouteModel
//
// // 故意不响应 Task.cancel()，用 continuation 精确控制返回顺序，不用 sleep 猜时序。
// actor ControlledBodyLoader: ArticleBodyLoading {
//     private var pending: [UUID: CheckedContinuation<String, Error>] = [:]
//     private var arrivals: [ArticleBodyRequest] = []
//     private var waiter: CheckedContinuation<ArticleBodyRequest, Never>?
//     func load(_ request: ArticleBodyRequest) async throws -> String {
//         try await withCheckedThrowingContinuation { continuation in
//             pending[request.id] = continuation
//             if let waiter { self.waiter = nil; waiter.resume(returning: request) }
//             else { arrivals.append(request) }
//         }
//     }
//     func nextRequest() async -> ArticleBodyRequest {
//         if !arrivals.isEmpty { return arrivals.removeFirst() }
//         return await withCheckedContinuation { waiter = $0 }
//     }
//     func finish(_ request: ArticleBodyRequest, _ result: Result<String, Error>) {
//         pending.removeValue(forKey: request.id)!.resume(with: result)
//     }
// }
//
// final class ArticleBodyTests: XCTestCase {
//     private func context(_ article: String = "A", version: Int = 1,
//                          category: String = "UIKit") -> ArticleBodyContext {
//         ArticleBodyContext(categoryID: category, articleID: article, contentVersion: version)
//     }
//     @MainActor
//     private func deliver(_ request: ArticleBodyRequest, _ result: Result<String, Error>,
//                          accepted: Bool, loader: ControlledBodyLoader,
//                          body: ArticleBodyCoordinator) async {
//         let done = expectation(description: "响应已处理")
//         body.onResponseProcessed = { actual, didAccept in
//             XCTAssertEqual(actual, request); XCTAssertEqual(didAccept, accepted); done.fulfill()
//         }
//         await loader.finish(request, result)
//         await fulfillment(of: [done], timeout: 3)
//         body.onResponseProcessed = nil
//     }
//     @MainActor
//     func testBFinishesBeforeA() async {
//         let loader = ControlledBodyLoader()
//         let state = ArticleBodyCoordinator(loader: loader)
//         state.synchronize(context: context()); let a = await loader.nextRequest()
//         state.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
//         XCTAssertEqual(state.state, .loading(b)) // A 正文立即清除。
//         await deliver(b, .success("B 新正文"), accepted: true, loader: loader, body: state)
//         await deliver(a, .success("A 旧正文"), accepted: false, loader: loader, body: state)
//         XCTAssertEqual(state.state, .loaded(b, "B 新正文"))
//     }
//     @MainActor
//     func testOldFailureAndCancellationCannotClearNewLoading() async {
//         for error in [NSError(domain: "测试", code: 500), CancellationError()] as [Error] {
//             let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//             body.synchronize(context: context()); let a = await loader.nextRequest()
//             body.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
//             await deliver(a, .failure(error), accepted: false, loader: loader, body: body)
//             XCTAssertEqual(body.state, .loading(b)); XCTAssertEqual(body.activeRequest, b)
//             await deliver(b, .success("B"), accepted: true, loader: loader, body: body)
//         }
//     }
//     @MainActor
//     func testSameArticleReloadUsesNewRequestIDWithoutVersionChange() async {
//         let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//         body.synchronize(context: context()); let first = await loader.nextRequest()
//         body.reload(); let second = await loader.nextRequest()
//         XCTAssertEqual(first.context, second.context); XCTAssertNotEqual(first.id, second.id)
//         await deliver(second, .success("刷新后的正文"), accepted: true, loader: loader, body: body)
//         await deliver(first, .success("刷新前的正文"), accepted: false, loader: loader, body: body)
//         XCTAssertEqual(body.state, .loaded(second, "刷新后的正文"))
//     }
//     @MainActor
//     func testAToBToADoesNotReviveFirstA() async {
//         let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//         body.synchronize(context: context()); let a1 = await loader.nextRequest()
//         body.synchronize(context: context("B", version: 2)); let b = await loader.nextRequest()
//         body.synchronize(context: context(version: 3)); let a2 = await loader.nextRequest()
//         await deliver(a1, .success("A 旧正文"), accepted: false, loader: loader, body: body)
//         await deliver(b, .success("B"), accepted: false, loader: loader, body: body)
//         XCTAssertEqual(body.state, .loading(a2))
//         await deliver(a2, .success("A 新正文"), accepted: true, loader: loader, body: body)
//     }
//     @MainActor
//     func testDeletionDuringGestureAndLayoutWinsForBothOutcomes() async {
//         for cancelled in [false, true] {
//             let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//             var library = ReadingLibrary(categoryID: "UIKit", articleID: "文章 A")
//             var route = RouteLedger(route: .detail)
//             body.synchronize(context: context("文章 A", version: route.contentVersion))
//             let request = await loader.nextRequest()
//             let back = route.beginNavigation(to: .list)!, layout = route.beginLayout()
//             library.deleteArticle("文章 A", in: "UIKit")
//             route.contentChanged(correctedRoute: library.correctedRoute(route.route))
//             body.synchronize(context: nil) // 立即失效，不等动画。
//             await deliver(request, .success("被删除的正文"), accepted: false, loader: loader, body: body)
//             route.endLayout(layout); route.finishNavigation(id: back.id, cancelled: cancelled)
//             XCTAssertEqual(body.state, .idle); XCTAssertNil(library.articleID)
//             XCTAssertEqual(route.takeReconciliation(), .list)
//         }
//     }
//     @MainActor
//     func testCategorySwitchAndReusedArticleID() async {
//         let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//         body.synchronize(context: context()); let old = await loader.nextRequest()
//         body.synchronize(context: nil)
//         body.synchronize(context: context(version: 3, category: "Swift"))
//         let current = await loader.nextRequest()
//         await deliver(old, .success("UIKit A"), accepted: false, loader: loader, body: body)
//         XCTAssertEqual(body.state, .loading(current))
//         await deliver(current, .success("Swift A"), accepted: true, loader: loader, body: body)
//     }
//     @MainActor
//     func testBackAndLayoutKeepRequestButDoNotRestoreDetail() async {
//         let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//         var route = RouteLedger(route: .detail)
//         body.synchronize(context: context()); let request = await loader.nextRequest()
//         let back = route.beginNavigation(to: .list)!, layout = route.beginLayout()
//         route.finishNavigation(id: back.id, cancelled: false); route.endLayout(layout)
//         body.synchronize(context: context())
//         XCTAssertEqual(body.activeRequest, request) // 相同上下文不产生重复请求。
//         await deliver(request, .success("A"), accepted: true, loader: loader, body: body)
//         XCTAssertEqual(route.route, .list)
//         XCTAssertEqual(body.state, .loaded(request, "A"))
//     }
//     @MainActor
//     func testCurrentFailureCanRetryAndCurrentCancellationEndsLoading() async {
//         let loader = ControlledBodyLoader(); let body = ArticleBodyCoordinator(loader: loader)
//         body.synchronize(context: context()); let first = await loader.nextRequest()
//         let error = NSError(domain: "测试", code: 500)
//         await deliver(first, .failure(error), accepted: true, loader: loader, body: body)
//         XCTAssertEqual(body.state, .failed(first, error.localizedDescription))
//         body.reload(); let second = await loader.nextRequest()
//         await deliver(second, .failure(CancellationError()), accepted: true, loader: loader, body: body)
//         XCTAssertEqual(body.state, .idle); XCTAssertNil(body.activeRequest)
//         body.reload(); let third = await loader.nextRequest()
//         await deliver(third, .success("重试成功"), accepted: true, loader: loader, body: body)
//     }
// }
//
// UI 另用 --body-controlled 启用可控服务，点击分类 / 文章 / 重新加载与删除按钮，
// 手动让新请求先回、旧请求后回，检查真正显示的正文和 loading，不只断言状态计数。
// 覆盖快速切换、删除后重新折叠、切换分类及同文章刷新；结果见 Verification/异步正文验证.md。
//
// MARK: - 24. 与 iOS 26 Inspector 的边界
//
// inspector 是额外的辅助列，不属于 DisplayMode 命名中 one / two 计数的侧栏。
// 同一个 .tripleColumn 容器可以再配置 .inspector，而不用更换 Style。
// inspector 的显示 / 隐藏也不应被当作 isCollapsed 的变化。
// 例如已经配置检查器内容后：
//   if #available(iOS 26.0, *) {
//       split.show(.inspector)
//       // 需要关闭时：split.hide(.inspector)
//       // 查询可见性：split.isShowing(.inspector)
//   }
// 折叠时，系统将 inspector 作为 secondary 上方的 sheet 呈现。
//
// 本节官方依据（状态、两种决策与两种完成通知）：
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/iscollapsed
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/column/compact
// https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/splitviewcontroller(_:topcolumnforcollapsingtoproposedtopcolumn:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/splitviewcontroller(_:displaymodeforexpandingtoproposeddisplaymode:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/splitviewcontrollerdidcollapse(_:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/splitviewcontrollerdidexpand(_:)
//
// MARK: - 25. 后续 API 阅读顺序与记号
//
// 建议：Style / Column → 初始化与内容配置 → show / hide → 显示规则 → 列宽 → 代理。
// 标为“传统样式”“已弃用”“进阶”的接口，第一次阅读可以暂时跳过。
// preferred = 希望采用的值；Width 使用点，WidthFraction 使用比例。
// “传统样式”指 .unspecified；“列式样式”指 .doubleColumn / .tripleColumn。
// iOS 26 接口需要可用性保护；原始版本标记均保留在下方声明上。
//
/// 下面是分栏控制器使用的枚举与常量。
/// 阅读时先看 Style（结构）和 Column（内容位置），再看 DisplayMode（显示组合）。
extension UISplitViewController {

    /// 显示模式：决定展开状态下，屏幕上显示哪些内容列、这些列如何排列。
    /// 例如三栏界面可以同时显示三列，也可以暂时只显示详情。
    /// 设置 preferredDisplayMode 表达希望的模式；读取 displayMode 查看实际结果。
    /// 命名中的 one / two 是“详情旁边的侧栏数量”：twoBesideSecondary 合计三列。
    /// 这里的侧栏指 primary / supplementary；inspector 的可见性另外控制。
    /// 如果 isCollapsed == true，界面已经折叠，本枚举不决定折叠后的页面外观。
    @available(iOS 8.0, *)
    public enum DisplayMode : Int, @unchecked Sendable {

        /// 让系统选择合适的显示模式。
        /// 用法：split.preferredDisplayMode = .automatic。
        /// 适合不想指定并排或覆盖方式的场景；实际的 split.displayMode 不会是 automatic。
        case automatic = 0

        /// 只显示详情，暂时隐藏分类栏和列表栏。
        /// 例：阅读文章时，希望让详情占据主要空间。
        /// 注意：只显示一列，不代表发生了“折叠”；是否折叠仍要看 isCollapsed。
        case secondaryOnly = 1

        /// 一个侧栏与详情并排显示，一共两列。
        /// 双栏结构：[primary 列表] [secondary 详情]。
        /// 三栏结构：[supplementary 列表] [secondary 详情]，此时 primary 分类栏隐藏。
        /// 适用于 tile / displace 行为。
        case oneBesideSecondary = 2

        /// 一个侧栏临时盖在详情上方，详情仍能露出一部分。
        /// 双栏时覆盖的是 primary；三栏时覆盖的是 supplementary。
        /// 适合需要临时打开列表、又不想一直为列表留空间的界面，对应 overlay 行为。
        case oneOverSecondary = 3

        /// 分类、列表、详情三栏同时并排显示。
        /// 示意：[primary 分类] [supplementary 列表] [secondary 详情]。
        /// 用法：split.preferredDisplayMode = .twoBesideSecondary。
        /// 仅适用于 tripleColumn；对应 tile 行为，且需要足够的可用空间。
        @available(iOS 14.0, *)
        case twoBesideSecondary = 4

        /// 分类栏和列表栏并排出现，一起覆盖在详情上方。
        /// 详情仍部分可见，但会变暗，不能直接操作其内容。
        /// 只适用于 tripleColumn，配合 overlay 行为。
        @available(iOS 14.0, *)
        case twoOverSecondary = 5

        /// 分类栏和列表栏出现时，把详情向另一侧推走一部分。
        /// 与 twoOverSecondary 的区别：这里是“推走”，不是两栏盖在详情上面。
        /// 被推到边缘的详情部分超出屏幕，并被遮罩，不能直接操作其内容。
        /// 只适用于 tripleColumn，配合 displace 行为。
        @available(iOS 14.0, *)
        case twoDisplaceSecondary = 6

        /// 【已弃用】旧名称，表示隐藏主栏、只显示详情。
        /// 新代码使用 .secondaryOnly；保留此项用于阅读或迁移旧项目。
        @available(iOS, introduced: 8.0, deprecated: 14.0, renamed: "UISplitViewController.DisplayMode.secondaryOnly")
        public static var primaryHidden: UISplitViewController.DisplayMode { get }

        /// 【已弃用】旧名称，表示传统双栏中的两栏并排显示。
        /// 新代码使用 .oneBesideSecondary。
        /// 不要根据 allVisible 理解为“三栏全显示”；三栏全显示应使用 .twoBesideSecondary。
        @available(iOS, introduced: 8.0, deprecated: 14.0, renamed: "UISplitViewController.DisplayMode.oneBesideSecondary")
        public static var allVisible: UISplitViewController.DisplayMode { get }

        /// 【已弃用】旧名称，表示主栏覆盖在详情上。
        /// 新代码使用 .oneOverSecondary。
        @available(iOS, introduced: 8.0, deprecated: 14.0, renamed: "UISplitViewController.DisplayMode.oneOverSecondary")
        public static var primaryOverlay: UISplitViewController.DisplayMode { get }
    }

    /// 主栏放在哪一侧。
    /// leading / trailing 会跟随语言的布局方向，不是固定的左 / 右。
    @available(iOS 11.0, *)
    public enum PrimaryEdge : Int, @unchecked Sendable {

        /// 布局的起始侧。中文、英文界面中通常是左侧。
        /// 例：常见的左侧分类导航栏。
        case leading = 0

        /// 布局的末尾侧。中文、英文界面中通常是右侧。
        /// 例：希望把主栏放在右侧时使用；从右到左的语言中位置相反。
        case trailing = 1
    }

    /// 主栏的背景外观，不负责决定列数、位置或宽度。
    @available(iOS 13.0, *)
    public enum BackgroundStyle : Int, @unchecked Sendable {

        /// 不额外采用系统侧栏背景样式。
        /// 注意：这不是把内容控制器的背景色设置成透明。
        case none = 0

        /// 采用系统的侧栏背景外观。
        /// 用法：split.primaryBackgroundStyle = .sidebar。
        case sidebar = 1
    }

    /// 结构样式：创建时决定使用双栏还是三栏。
    /// 双栏适合“列表 → 详情”；三栏适合“分类 → 列表 → 详情”。
    /// 三栏结构在窄屏上仍可能只显示一个页面；style 不等于当前可见列数。
    /// 最低支持 iOS 15 的新项目，通常从 doubleColumn / tripleColumn 开始。
    @available(iOS 14.0, *)
    public enum Style : Int, @unchecked Sendable {

        /// 【传统样式】表示采用较早的 primary / secondary 管理方式。
        /// 不是“自动选择双栏或三栏”。
        /// 阅读旧代码时会遇到它；新建本例应使用 init(style: .tripleColumn)。
        /// 这种样式不能使用 setViewController(_:for:) 等列式专用接口。
        case unspecified = 0

        /// 双栏结构：primary + secondary。
        /// 例：左侧联系人列表，右侧联系人详情。
        /// 用法：UISplitViewController(style: .doubleColumn)。
        case doubleColumn = 1

        /// 三栏结构：primary + supplementary + secondary。
        /// 例：左侧邮件分类，中间邮件列表，右侧邮件正文。
        /// 用法：UISplitViewController(style: .tripleColumn)。
        /// 双栏和三栏在 iOS 26 都可额外配置 inspector。
        case tripleColumn = 2
    }

    /// 列的名字：告诉容器“这个页面属于哪个位置”。
    /// 常用法：setViewController(vc, for: .secondary) 把 vc 放到详情位置。
    /// 枚举原始值不是 viewControllers 数组下标，不能据此按下标取控制器。
    /// 某列有内容，也不代表它此刻可见。
    @available(iOS 14.0, *)
    public enum Column : Int, @unchecked Sendable {

        /// 主栏：导航链中最前面的那一层。
        /// 三栏示例中放“分类”；双栏示例中通常放“列表”。
        case primary = 0

        /// 补充栏：三栏结构中位于分类和详情之间的列表。
        /// 例：选中“收件箱”后，在这里列出邮件。
        /// 仅用于 tripleColumn。
        case supplementary = 1

        /// 详情栏：显示用户当前选择的内容。
        /// 例：文章正文、邮件正文或联系人详情。
        /// 虽然名字是 secondary，在三栏中它实际是第三个内容位置。
        case secondary = 2

        /// 【进阶】为窄屏折叠状态单独准备的一套页面。
        /// 如果设置这一列，折叠后显示它，而不是默认组合已有的分类、列表、详情导航。
        /// 入门示例可以先不设置，让 UIKit 处理已有三列的折叠导航。
        /// 它不是宽屏时的第四列，也不能传给 show(_ column:) / hide(_ column:)。
        case compact = 3

        /// 【iOS 26+】检查器：为详情提供辅助信息或操作的额外面板。
        /// 例：正文在 secondary 中，字体、标签、文件属性放在 inspector 中。
        /// 展开时位于 trailing 一侧；折叠时系统以 sheet 呈现。
        /// 配置：setViewController(inspectorVC, for: .inspector)。
        /// 控制：show(.inspector) / hide(.inspector)；默认隐藏。
        /// 最低 iOS 15 的项目使用它时，需要 if #available(iOS 26.0, *)。
        @available(iOS 26.0, *)
        case inspector = 4
    }

    /// 分栏行为：侧栏出现时，如何与详情分配空间。
    /// 先区分三种动作：tile 并排、overlay 覆盖、displace 推走。
    /// 它还限制可用的 DisplayMode；例如 overlay 配合 oneOverSecondary / twoOverSecondary。
    /// 初学三栏并排布局时，可以先用 preferredSplitBehavior = .tile。
    @available(iOS 14.0, *)
    public enum SplitBehavior : Int, @unchecked Sendable {

        /// 让系统根据当前窗口环境选择并排、覆盖等行为。
        /// 用法：split.preferredSplitBehavior = .automatic。
        case automatic = 0

        /// 并排：侧栏和详情各占一块空间。
        /// 适合宽屏上同时浏览分类、列表和详情。
        /// 可使用 secondaryOnly、oneBesideSecondary、twoBesideSecondary；最后一个仅用于三栏。
        case tile = 1

        /// 覆盖：侧栏临时盖在详情上，详情仍部分可见但被遮罩。
        /// 可使用 secondaryOnly、oneOverSecondary、twoOverSecondary；最后一个仅用于三栏。
        case overlay = 2

        /// 挤移：两个侧栏出现时，把详情的一部分推到屏幕之外。
        /// 只显示一个侧栏时仍可并排。
        /// 可使用 secondaryOnly、oneBesideSecondary、twoDisplaceSecondary；最后一个仅用于三栏。
        case displace = 3
    }

    /// 控制系统“切换侧栏显示模式”按钮是否出现。
    /// 它只控制按钮，不直接显示或隐藏某一列。
    @available(iOS 14.5, *)
    public enum DisplayModeButtonVisibility : Int, @unchecked Sendable {

        /// 由系统决定按钮是否出现，是默认策略。
        /// 在该策略下，presentsWithGesture = false 也会让此按钮隐藏。
        case automatic = 0

        /// 不显示系统提供的显示模式按钮。
        /// 例：你已在界面中提供了自己的侧栏开关。
        case never = 1

        /// 即使禁用了系统滑动手势，也允许系统显示该按钮。
        /// 例：presentsWithGesture = false，同时 displayModeButtonVisibility = .always。
        /// 名字虽然是 always，但当前模式不需要这个按钮时，仍不会强制出现。
        case always = 2
    }

    /// “交给系统决定尺寸”的特殊常量，不能当作普通点数理解。
    /// 例：split.preferredPrimaryColumnWidth = UISplitViewController.automaticDimension。
    /// 从定宽切换到比例宽度前，可用它清除之前的绝对首选宽度。
    @available(iOS 8.0, *)
    public class let automaticDimension: CGFloat
}

/// 把多个页面组织成分栏或折叠导航的容器控制器。
/// 你负责创建各列的 UIViewController、更新选中的数据；UIKit 负责列的呈现和转场。
/// 常见结构：分类 → 列表 → 详情。宽屏可并排，窄屏可逐层进入和返回。
/// 它不会替你创建业务内容，也不会自动知道用户选中了哪篇文章。
/// @MainActor 表示 UI 操作受主 actor 隔离。
@available(iOS 3.2, *)
@MainActor open class UISplitViewController : UIViewController {

    /// 从 storyboard 或归档等编码数据中创建控制器。
    /// 纯代码创建本例时不需要调用它；问号表示初始化可能失败并返回 nil。
    public init?(coder: NSCoder)

    /// 使用 nib 文件及资源 bundle 创建控制器的传统初始化入口。
    /// 要明确创建现代双栏 / 三栏，优先看下面的 init(style:)。
    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)

    /// 【常用入口】创建指定结构的分栏容器。
    /// 例：let split = UISplitViewController(style: .tripleColumn)。
    /// 创建后再用 setViewController(_:for:) 给每一列提供内容。
    /// style 决定可管理哪些普通内容列，不保证它们一直同时显示。
    @available(iOS 14.0, *)
    public init(style: UISplitViewController.Style)

    /// 查看容器创建时选用的结构，例如 doubleColumn 或 tripleColumn。
    /// 这是只读属性；不能通过 split.style = ... 动态改成另一种结构。
    /// 只想改变当前可见列，应使用 show / hide 或 preferredDisplayMode。
    @available(iOS 14.0, *)
    open var style: UISplitViewController.Style { get }

    /// 让一个对象接收分栏变化通知，或参与折叠 / 展开的决策。
    /// 例：控制器遵守 UISplitViewControllerDelegate 后，设置 split.delegate = self。
    /// 不需要自定义时可以不设置。
    /// 这是弱引用；独立创建的代理需要由其他对象持有，避免立即释放。
    weak open var delegate: (any UISplitViewControllerDelegate)?

    /// 三栏界面中，是否提供快速切换到“只看详情”的系统按钮。
    /// 例：阅读正文时需要更大空间，可设置为 true；默认 false。
    /// 它与显示普通侧栏开关的 displayModeButtonVisibility 是两个不同配置。
    @available(iOS 14.0, *)
    open var showsSecondaryOnlyButton: Bool

    /// 设置你希望采用的分栏行为。
    /// 例：split.preferredSplitBehavior = .tile，让内容尽量并排。
    /// 默认 automatic；后续布局时生效，实际采用的值读取 splitBehavior。
    @available(iOS 14.0, *)
    open var preferredSplitBehavior: UISplitViewController.SplitBehavior

    /// 查看系统当前实际采用的分栏行为，只读。
    /// 与 preferredSplitBehavior 的区别：preferred 是你的请求，这个属性是布局结果。
    @available(iOS 14.0, *)
    open var splitBehavior: UISplitViewController.SplitBehavior { get }

    /// 【常用】把一个页面安排到指定列，或替换该列已有的页面。
    /// 例：split.setViewController(UINavigationController(rootViewController: detailVC), for: .secondary)。
    /// vc 是内容控制器，column 是位置；传 nil 表示清除该位置关联的控制器。
    /// 仅用于 doubleColumn / tripleColumn；三栏才有 supplementary。
    /// 普通内容控制器通常会被系统包在导航控制器中，已有导航结构存在例外；compact 按原样使用。
    /// “放入内容”与“请求显示”是不同操作；例如配置 inspector 后，再用 show(.inspector) 打开它。
    @available(iOS 14.0, *)
    open func setViewController(_ vc: UIViewController?, for column: UISplitViewController.Column)

    /// 取回某列关联的控制器；没有配置时返回 nil。
    /// 例：let detail = split.viewController(for: .secondary)。
    /// 仅用于列式样式。返回非 nil 不代表该列正在显示；iOS 26 可用 isShowing 查询可见性。
    @available(iOS 14.0, *)
    open func viewController(for column: UISplitViewController.Column) -> UIViewController?

    /// 【常用】请求把某列从当前界面隐藏，但保留该列的内容配置。
    /// 例：split.hide(.primary)；iOS 26 可用 split.hide(.inspector) 关闭检查器。
    /// 展开时，通过改变显示组合隐藏侧栏；隐藏 secondary 的请求会被忽略。
    /// 默认折叠导航中，只能弹出当前顶部且不是 primary 的列；其他情况不做操作。
    /// 独立 compact 内部的返回应使用其自己的导航控制器，不用本方法代替 pop。
    /// 完整点击与返回流程见文件开头第 11～15 节。
    /// 不能传 .compact；需要清除内容时使用 setViewController(nil, for: ...)。
    @available(iOS 14.0, *)
    open func hide(_ column: UISplitViewController.Column)

    /// 【常用】请求显示已经配置好内容的那一列。
    /// 例：点击文章后，先更新详情数据，再调用 split.show(.secondary)。
    /// 展开时，对 secondary 的请求被忽略；对侧栏则按当前行为切换到最近的可见模式。
    /// 默认折叠时，目标不在栈中则推入目标及中间列；已在顶部不操作；被覆盖则返回到目标。
    /// 独立 compact 中的业务导航由自己的控制器负责，不用本方法代替内部 push / pop。
    /// 展开时 show(.secondary) 不会替你收起侧栏；完整三种情况见开头第 11～15 节。
    /// 不接受 .compact；iOS 26 可用 show(.inspector) 打开检查器。
    /// 注意与 show(_ vc:sender:) 区分：这里传的是列名，不是新的控制器。
    @available(iOS 14.0, *)
    open func show(_ column: UISplitViewController.Column)

    /// 【iOS 26+】询问某一列现在是否显示。
    /// 例：if split.isShowing(.inspector) { split.hide(.inspector) }。
    /// 用它同步检查器按钮状态，比自己保存一个 Bool 更能反映系统改变后的真实结果。
    /// 最低 iOS 15 的项目需要先做 #available 检查。
    @available(iOS 26.0, *)
    open func isShowing(_ column: UISplitViewController.Column) -> Bool

    /// 容器管理的内容控制器数组。
    /// 阅读传统样式代码时，常见 [主控制器, 详情控制器] 的配置方式。
    /// 新建本例使用 setViewController(_:for:) 按列名配置，不需要记数组顺序。
    /// 折叠可能改变数组，不要把 Column.rawValue 当作数组下标。
    open var viewControllers: [UIViewController]

    /// 是否允许系统用滑动手势显示或收起隐藏内容，默认 true。
    /// 例：split.presentsWithGesture = false 可禁用这种系统分栏手势。
    /// 列式样式的默认按钮策略也受它影响；想禁用手势但保留按钮，可配合 .always。
    @available(iOS 5.1, *)
    open var presentsWithGesture: Bool

    /// 【常用判断】当前是否已经折叠成单列呈现结构。
    /// 例：if split.isCollapsed { /* 当前使用折叠界面 */ }。
    /// 不要用“当前只看到详情”推断它：宽屏只显示 secondary 时，也可能没有折叠。
    /// 判断的是容器状态，不是 iPhone / iPad 的设备型号。
    @available(iOS 8.0, *)
    open var isCollapsed: Bool { get }

    /// 【常用设置】告诉系统你希望怎么显示普通内容列。
    /// 例：split.preferredDisplayMode = .twoBesideSecondary，请求三栏并排。
    /// automatic 表示交给系统决定；空间不够时，系统不一定采用你的首选组合。
    /// 实际结果看 displayMode；折叠时此属性不决定页面外观，也不强制取消折叠。
    @available(iOS 8.0, *)
    open var preferredDisplayMode: UISplitViewController.DisplayMode

    /// 读取当前实际的显示模式，只读，不会返回 automatic。
    /// 例：检查是否已经采用 .twoBesideSecondary 的三栏并排模式。
    /// 它与 preferredDisplayMode 可能不同；是否折叠仍看 isCollapsed。
    /// inspector 是否可见需要单独查询，不能只看这个枚举。
    @available(iOS 8.0, *)
    open var displayMode: UISplitViewController.DisplayMode { get }

    /// 【传统样式】系统提供的显示模式按钮，可放入详情页导航栏。
    /// 例：detailVC.navigationItem.leftBarButtonItem = split.displayModeButtonItem。
    /// 点击后的目标模式由系统或 targetDisplayModeForAction(in:) 决定。
    /// 现代列式样式不使用这个属性管理按钮，应看 displayModeButtonVisibility。
    @available(iOS 8.0, *)
    open var displayModeButtonItem: UIBarButtonItem { get }

    /// 配置现代列式界面中系统侧栏开关按钮的可见性，默认 automatic。
    /// 例：split.displayModeButtonVisibility = .always。
    /// 常用于禁用手势后仍希望保留按钮；always 不是在任何显示模式下都强制显示。
    @available(iOS 14.5, *)
    open var displayModeButtonVisibility: UISplitViewController.DisplayModeButtonVisibility

    /// 按容器总宽度的比例设置主栏首选宽度，通常填写 0.0～1.0。
    /// 例：0.25 表示希望主栏占容器宽度的 25%，不是 25 点。
    /// 如果 preferredPrimaryColumnWidth 已设置具体点数，要先恢复 automaticDimension，比例才优先生效。
    /// 最终宽度还受最小值、最大值和可用空间限制；默认使用 automaticDimension。
    @available(iOS 8.0, *)
    open var preferredPrimaryColumnWidthFraction: CGFloat

    /// 按点数设置主栏首选宽度。
    /// 例：split.preferredPrimaryColumnWidth = 240。
    /// 非 automaticDimension 的值优先于比例宽度；默认 automaticDimension。
    /// 240 是希望采用的值，不是强制约束；实际布局还要考虑可用空间和上下限。
    @available(iOS 14.0, *)
    open var preferredPrimaryColumnWidth: CGFloat

    /// 主栏的最小宽度设置，单位是点。
    /// 例：split.minimumPrimaryColumnWidth = 200，避免分类内容过窄。
    /// 默认 automaticDimension；最小值应不大于你设置的最大值。
    @available(iOS 8.0, *)
    open var minimumPrimaryColumnWidth: CGFloat

    /// 主栏的最大宽度设置，单位是点。
    /// 例：split.maximumPrimaryColumnWidth = 320，避免大窗口中分类栏过宽。
    /// 默认 automaticDimension；它限制宽度范围，不会要求主栏一直等于这个宽度。
    @available(iOS 8.0, *)
    open var maximumPrimaryColumnWidth: CGFloat

    /// 读取主栏当前实际计算出的宽度，单位是点，不能直接赋值。
    /// 适合布局完成后查看和调试；想改变宽度，应改 preferred / minimum / maximum 属性。
    /// 排版文字和按钮时仍应遵守子控制器的安全区，不能把整个控制器宽度都当作无遮挡区域。
    @available(iOS 8.0, *)
    open var primaryColumnWidth: CGFloat { get }

    /// 按容器总宽度的比例设置补充栏首选宽度，仅用于三栏。
    /// 例：split.preferredSupplementaryColumnWidthFraction = 0.25。
    /// 先把 preferredSupplementaryColumnWidth 恢复 automaticDimension，避免具体点数覆盖比例设置。
    /// 默认 automaticDimension；实际结果还受上下限和可用空间影响。
    @available(iOS 14.0, *)
    open var preferredSupplementaryColumnWidthFraction: CGFloat

    /// 按点数设置补充栏（中间列表）的首选宽度。
    /// 例：split.preferredSupplementaryColumnWidth = 280。
    /// 默认 automaticDimension；具体点数优先于 preferredSupplementaryColumnWidthFraction。
    @available(iOS 14.0, *)
    open var preferredSupplementaryColumnWidth: CGFloat

    /// 补充栏的最小宽度设置，单位是点。
    /// 例：split.minimumSupplementaryColumnWidth = 240。
    /// 默认 automaticDimension，交给系统选择默认下限。
    @available(iOS 14.0, *)
    open var minimumSupplementaryColumnWidth: CGFloat

    /// 补充栏的最大宽度设置，单位是点。
    /// 例：split.maximumSupplementaryColumnWidth = 380。
    /// 默认 automaticDimension；用于限制中间列表在宽屏上占据过多空间。
    @available(iOS 14.0, *)
    open var maximumSupplementaryColumnWidth: CGFloat

    /// 读取补充栏控制器当前的实际宽度，单位是点，只读。
    /// 注意 iOS 26 的侧栏可能让相邻控制器延伸到其后方，因此这个读数可能包含被侧栏覆盖的区域。
    /// 布局可见内容时使用子控制器的 safeAreaLayoutGuide；不要仅拿此值与首选宽度做相等比较。
    @available(iOS 14.0, *)
    open var supplementaryColumnWidth: CGFloat { get }

    /// 【iOS 26+】按比例设置详情栏首选宽度；默认 automaticDimension。
    /// 例：split.preferredSecondaryColumnWidthFraction = 0.5，表达希望占容器宽度一半。
    /// 若同时设置了非自动的 preferredSecondaryColumnWidth，具体点数优先。
    /// iOS 15 中不要调用该属性，详情区域交由已有分栏布局分配。
    @available(iOS 26.0, *)
    open var preferredSecondaryColumnWidthFraction: CGFloat

    /// 【iOS 26+】按点数设置详情栏首选宽度；默认 automaticDimension。
    /// 例：split.preferredSecondaryColumnWidth = 600。
    /// 具体点数优先于比例配置，但最终结果仍由 UIKit 结合窗口空间决定。
    @available(iOS 26.0, *)
    open var preferredSecondaryColumnWidth: CGFloat

    /// 【iOS 26+】设置详情区域的最小宽度，单位是点。
    /// 例：split.minimumSecondaryColumnWidth = 320。
    /// 默认 automaticDimension；这份 API 声明没有对应的 maximumSecondaryColumnWidth。
    @available(iOS 26.0, *)
    open var minimumSecondaryColumnWidth: CGFloat

    /// 【iOS 26+】按容器宽度比例设置检查器首选宽度。
    /// 例：split.preferredInspectorColumnWidthFraction = 0.2。
    /// 默认 automaticDimension；非自动的 preferredInspectorColumnWidth 优先于它。
    @available(iOS 26.0, *)
    open var preferredInspectorColumnWidthFraction: CGFloat

    /// 【iOS 26+】按点数设置检查器首选宽度。
    /// 例：split.preferredInspectorColumnWidth = 280。
    /// 默认 automaticDimension；还受检查器最小 / 最大宽度及可用空间限制。
    @available(iOS 26.0, *)
    open var preferredInspectorColumnWidth: CGFloat

    /// 【iOS 26+】检查器最小宽度，单位是点。
    /// 例：split.minimumInspectorColumnWidth = 240；默认 automaticDimension。
    @available(iOS 26.0, *)
    open var minimumInspectorColumnWidth: CGFloat

    /// 【iOS 26+】检查器最大宽度，单位是点。
    /// 例：split.maximumInspectorColumnWidth = 360；默认 automaticDimension。
    @available(iOS 26.0, *)
    open var maximumInspectorColumnWidth: CGFloat

    /// 把主栏安排在布局起始侧还是末尾侧，默认 leading。
    /// 例：split.primaryEdge = .trailing。
    /// 中文、英文界面通常把 trailing 理解为右侧；实际位置仍跟随语言布局方向。
    @available(iOS 11.0, *)
    open var primaryEdge: UISplitViewController.PrimaryEdge

    /// 展示一个新的控制器，让容器根据当前结构选择合适的展示方式。
    /// 参数 vc 是新页面；sender 是触发本次操作的对象，不需要时可传 nil。
    /// 例：split.show(nextVC, sender: self)。
    /// 它不是 show(.secondary)：前者传新页面，后者让已有详情列显示出来。
    /// 刚开始学习列式布局时，优先用 setViewController(_:for:) 明确配置各列。
    @available(iOS 8.0, *)
    open func show(_ vc: UIViewController, sender: Any?)

    /// 表达“请把这个新页面作为详情展示”的请求。
    /// 例：split.showDetailViewController(detailVC, sender: self)。
    /// 展开时通常在详情位置显示；折叠时由容器适配成导航推进等方式。
    /// 不要假定它一定执行 push 或一定执行模态 present，具体由容器层级决定。
    @available(iOS 8.0, *)
    open func showDetailViewController(_ vc: UIViewController, sender: Any?)

    /// 设置主栏背景的系统外观。
    /// 例：split.primaryBackgroundStyle = .sidebar。
    /// 改变的是背景风格，不是把某个控制器变成主栏，也不改变列宽。
    @available(iOS 13.0, *)
    open var primaryBackgroundStyle: UISplitViewController.BackgroundStyle
}

/// 代理协议：让你接收分栏变化通知，或告诉系统下一步该怎么显示。
/// 先设置 split.delegate = self，再实现需要的方法；所有方法都是可选的。
/// 有返回值的方法通常参与决策；will / did 开头的通知通常用来同步界面。
/// 现代三栏入门先看 topColumnForCollapsing... 与 displayModeForExpanding... 两个方法。
/// 标为“传统样式”的合并 / 拆分代理不用与现代列式代理混在一起实现。
@MainActor public protocol UISplitViewControllerDelegate {

    /// 显示模式即将改变时通知你，可提前更新相关按钮或提示。
    /// 参数 displayMode 是准备切换到的模式，不是已经完成的结果。
    /// 例如准备切到 secondaryOnly 时，可以更新“只看详情”的提示状态。
    @available(iOS 8.0, *)
    optional func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode)

    /// 【传统样式】用户使用系统手势或显示模式按钮时，询问下一步切到什么模式。
    /// 返回你希望的 DisplayMode；返回 .automatic 则继续由系统决定。
    /// 不适用于现代三栏的系统按钮策略，入门本例可以先跳过。
    @available(iOS 8.0, *)
    optional func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode

    /// 【传统样式】系统收到 show(_:sender:) 请求后，先问代理是否自己负责展示。
    /// vc 是要显示的页面；sender 是请求来源。
    /// 返回 true：你已经接管展示，系统不再执行默认展示。
    /// 返回 false：请系统继续执行默认展示。true 不是“允许系统展示”的意思。
    @available(iOS 8.0, *)
    optional func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool

    /// 【传统样式】系统收到 showDetailViewController(_:sender:) 请求后，询问代理是否接管。
    /// 返回 true：由你的实现完成详情展示。
    /// 返回 false 或不实现：系统按默认方式展示。
    /// 用于自定义旧式详情导航，不用于决定某个现代 Column 是否可见。
    @available(iOS 8.0, *)
    optional func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool

    /// 【传统样式】准备折叠时，询问哪个控制器作为折叠后的主控制器。
    /// 返回你的控制器；返回 nil 则保留默认选择，通常是已有 primary。
    /// 现代三栏选择折叠后显示哪列，应看 topColumnForCollapsing...。
    @available(iOS 8.0, *)
    optional func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController?

    /// 【传统样式】准备展开时，询问哪个控制器放回主栏。
    /// 返回你的主控制器；返回 nil 则采用默认选择，通常沿用已有 primary。
    @available(iOS 8.0, *)
    optional func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController?

    /// 【传统样式】折叠时，处理“详情内容要不要并入主界面、如何并入”。
    /// 例：详情只是“请选择项目”的占位页面时，你可能不希望它进入窄屏导航。
    /// 返回 true：不要再做系统默认合并；你已处理或明确决定不合并详情。
    /// 返回 false：继续默认流程，包括调用主控制器的 collapseSecondaryViewController(_:for:)。
    /// 它不是现代三栏决定顶部列的代理。
    @available(iOS 8.0, *)
    optional func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool

    /// 【传统样式】从折叠界面展开时，询问哪个控制器作为独立详情栏。
    /// 你可以从主界面中拆出详情并返回，同时整理好主控制器的层级。
    /// 返回 nil 表示交给默认拆分流程，不表示强制把详情设为空。
    @available(iOS 8.0, *)
    optional func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController?

    /// 询问这个分栏界面支持哪些屏幕方向。
    /// 返回方向集合，例如 .allButUpsideDown；也可以只允许 .portrait。
    /// 系统还会结合 App 和当前环境限制，不是返回什么就能强制旋转到什么。
    @available(iOS 7.0, *)
    optional func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask

    /// 询问呈现这个分栏界面时，你优先希望采用哪一个方向。
    /// 例：返回 .landscapeLeft 表示偏好横屏。
    /// 它与 supportedInterfaceOrientations 的区别：这里返回一个方向，后者返回允许的集合。
    @available(iOS 7.0, *)
    optional func splitViewControllerPreferredInterfaceOrientationForPresentation(_ splitViewController: UISplitViewController) -> UIInterfaceOrientation

    /// 【已弃用】旧式主栏将隐藏时，系统给你一个“重新打开主栏”的按钮。
    /// 旧代码通常把 barButtonItem 放到详情页导航栏或工具栏；pc 是相关 popover。
    /// iOS 8 起弃用。保留供旧项目迁移，新示例不用实现。
    @available(iOS, introduced: 2.0, deprecated: 8.0, message: "Use splitViewController:willChangeToDisplayMode: and displayModeButtonItem instead")
    optional func splitViewController(_ svc: UISplitViewController, willHide aViewController: UIViewController, with barButtonItem: UIBarButtonItem, for pc: UIPopoverController)

    /// 【已弃用】旧式主栏重新显示时，通知你移除之前的打开按钮。
    /// aViewController 是即将显示的控制器，barButtonItem 是已不再需要的按钮。
    /// iOS 8 起弃用，新示例不用实现。
    @available(iOS, introduced: 2.0, deprecated: 8.0, message: "Use splitViewController:willChangeToDisplayMode: and displayModeButtonItem instead")
    optional func splitViewController(_ svc: UISplitViewController, willShow aViewController: UIViewController, invalidating barButtonItem: UIBarButtonItem)

    /// 【已弃用】旧式主栏即将通过 popover 显示时的通知。
    /// 旧项目可在这里协调其他弹出界面，例如先关闭已有 popover。
    /// iOS 8 起弃用，新示例不用实现。
    @available(iOS, introduced: 2.0, deprecated: 8.0)
    optional func splitViewController(_ svc: UISplitViewController, popoverController pc: UIPopoverController, willPresent aViewController: UIViewController)

    /// 【已弃用】按屏幕方向判断是否隐藏旧式主栏。
    /// 返回 true 表示隐藏，false 表示保持显示。
    /// iOS 8 起弃用，现代分栏使用显示模式与窗口环境适配。
    @available(iOS, introduced: 5.0, deprecated: 8.0)
    optional func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool

    /// 【常用：列式样式】准备从展开布局变成折叠布局时，询问折叠后先显示哪列。
    /// 参数 proposedTopColumn 是系统建议；原样返回表示接受系统建议。
    /// 例：已选中文章就返回 .secondary，让用户继续阅读；没有选择时返回 .primary。
    /// 这里决定的是目标列，不需要自己手工移动三列控制器。
    /// 如果另外配置了 .compact 页面，折叠内容由那套页面承担。
    @available(iOS 14.0, *)
    optional func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column

    /// 【常用：列式样式】准备从折叠布局展开时，询问展开后采用哪种显示模式。
    /// 参数 proposedDisplayMode 是系统建议；可以原样返回。
    /// 例：本例返回 .twoBesideSecondary，请求恢复分类、列表、详情三栏并排。
    /// 适用模式还要与 style / splitBehavior 匹配；返回值不改变创建时的结构样式。
    @available(iOS 14.0, *)
    optional func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode

    /// 【列式样式】通知你：界面已经折叠。
    /// 例：更新“当前为窄屏导航”的提示；此时应做状态同步，不是在这里重新决定合并流程。
    /// 只有需要响应这个事件时才实现。
    @available(iOS 14.0, *)
    optional func splitViewControllerDidCollapse(_ svc: UISplitViewController)

    /// 【列式样式】通知你：界面已经展开。
    /// 例：更新布局提示或恢复适合多栏的辅助界面。
    /// 与 displayModeForExpanding... 的区别：前者决定展开到什么模式，这里通知展开已发生。
    @available(iOS 14.0, *)
    optional func splitViewControllerDidExpand(_ svc: UISplitViewController)

    /// 【列式样式】某一列即将显示，column 告诉你是哪一列。
    /// 例：显示前准备该列的提示或相关控件。
    /// 这是通知，没有 Bool 返回值，不能靠这个方法拒绝显示。
    @available(iOS 14.0, *)
    optional func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column)

    /// 【列式样式】某一列即将隐藏。
    /// 例：收起与这列相关的临时提示。
    /// 隐藏只是改变呈现状态，不代表控制器被删除或内容配置被清空。
    @available(iOS 14.0, *)
    optional func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column)

    /// 【iOS 26+】某一列已经完成显示。
    /// 例：column 为 .inspector 时，把自己的按钮更新为“隐藏检查器”。
    /// 如需确认实际状态，可在这里读取 svc.isShowing(column)。
    @available(iOS 26.0, *)
    optional func splitViewController(_ svc: UISplitViewController, didShow column: UISplitViewController.Column)

    /// 【iOS 26+】某一列已经完成隐藏。
    /// 例：检查器被关闭后，把按钮更新为“显示检查器”。
    /// 可响应系统引起的可见性变化，不必只依赖按钮点击时自己记录的状态。
    @available(iOS 26.0, *)
    optional func splitViewController(_ svc: UISplitViewController, didHide column: UISplitViewController.Column)

    /// 【进阶】系统用于显示分栏内容的交互式手势即将开始。
    /// 例：你的界面也有拖动操作时，可以在这里协调两种交互。
    /// 不是每次点击按钮，也不是所有子视图手势都会触发这个回调。
    @available(iOS 14.0, *)
    optional func splitViewControllerInteractivePresentationGestureWillBegin(_ svc: UISplitViewController)

    /// 【进阶】系统的交互式分栏呈现手势已经结束。
    /// 例：恢复刚才为了协调手势而暂停的操作。
    /// 手势可能取消，结束不等于目标列已显示；应结合实际显示模式或列可见性判断。
    @available(iOS 14.0, *)
    optional func splitViewControllerInteractivePresentationGestureDidEnd(_ svc: UISplitViewController)
}

/// 这些扩展让普通内容页面找到所属分栏容器，或参与传统样式的折叠 / 拆分。
extension UIViewController {

    /// 从当前页面找到上层的分栏控制器；不在分栏层级中时返回 nil。
    /// 例：详情页面里调用 splitViewController?.show(.primary)，请求显示分类栏。
    /// 即使中间隔着 UINavigationController，也可以沿祖先层级找到它。
    /// 注意可选链 ?.：页面不在分栏中时不会执行后续调用。
    open var splitViewController: UISplitViewController? { get }

    /// 【传统样式】由主控制器处理“折叠时如何容纳详情”的重写点。
    /// 当代理没有接管合并时，UIKit 把机会交给主控制器的这个方法。
    /// 普通 UIViewController 默认不整合详情；UINavigationController 有专门的导航栈处理。
    /// 只有编写自定义传统容器时通常才需要重写，现代三栏入门可以先跳过。
    @available(iOS 8.0, *)
    open func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController)

    /// 【传统样式】由主控制器在展开时提供独立详情的重写点。
    /// 代理没有提供自定义拆分结果时，默认流程会使用这个扩展点。
    /// 普通 UIViewController 的默认行为恢复此前的详情；自定义容器可重写以拆开自己的层级。
    /// 它与 collapseSecondaryViewController(_:for:) 配合处理传统合并 / 拆分。
    @available(iOS 8.0, *)
    open func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController?
}

// 语义核对参考（Apple Developer Documentation 与本机 UIKit SDK 头文件）：
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller
// https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/displaymode-swift.enum
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/setviewcontroller(_:for:)
// https://developer.apple.com/documentation/uikit/uisplitviewcontroller/column/inspector
// https://developer.apple.com/videos/play/wwdc2025/282/
