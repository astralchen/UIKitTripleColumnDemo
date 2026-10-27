# 默认折叠交错验证示例

打开 `TripleColumnDemo.xcworkspace`，使用 `TripleColumnDemo` scheme，最低 iOS 15。

核心 UIKit 源码在 `TripleColumnDemoPackage/Sources/TripleColumnDemoFeature/DefaultRouteSplit.swift`；它依赖仓库根目录的 `RouteModel` 本地包。请保留示例与仓库的相对路径。

`DefaultRouteHost` 是验证外壳，用容器宽度与尺寸类别覆盖制造宽窄切换。`--overlap-active` 和 `--overlap-decision` 仅在测试启动参数中启用，用来在真实返回转场中触发展开；生产逻辑不依赖这些参数。

系统返回与手势结果通过 UIKit 转场 completion 读取，模型按导航事务 ID 接收结果；布局版本只淘汰过期页面出现凭证。完整说明、状态图与实际验证边界见仓库 `Documentation` 和 `Verification`。

内容失效用例还会在真实转场中注入删除 / 分类切换事件，并检查旧正文消失、内容版本不匹配的结果被忽略、恢复后列表可点击。数据事件接口不受 `canNavigate` 限制；它们先清理数据和无效选择，再等容器转换完成。

`--content-delete`、`--content-switch`、`--content-active`、`--content-expand`、`--content-layout-delete` 均为验证外壳的启动参数，不是业务逻辑的依赖。详见仓库 `Verification/内容失效验证.md`。

正文加载通过 `ArticleBodyLoading` 注入，默认用异步延迟模拟。详情第三行“重新加载正文”会为同一文章生成新的请求 ID。正文响应只更新详情数据，不修改选择或 route。

用 Xcode 的 Scheme → Run → Arguments 添加 `--body-controlled` 可启用乱序验证面板：先选 A、再选 B，点击“返回新请求”让 B 返回，再点“返回旧请求”让 A 晚到；也可加载中删除 A、切到 Swift，或连续重载同一文章。顶部 pending 显示服务仍扣留的请求数量，bodyResponses 显示已处理（接收或丢弃）的响应数量。测试服务故意忽略取消，正式服务仍应尽力响应取消以节省资源。记录见 `Verification/异步正文验证.md`。
