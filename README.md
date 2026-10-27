# UISplitViewController 中文注释与默认折叠导航

最低部署 iOS 15。阅读稿保留原始 SDK 声明，并包含四个核心概念、三栏配置、默认折叠、独立 `.compact`、`show` / `hide`、route 恢复及手势与布局交错处理。

- [中文注释版.swift](Documentation/UISplitViewController-中文注释.swift)：所有教学代码都在注释中；不要把整份 SDK 声明加入编译目标。
- [四个核心概念交互图](Documentation/split-view-concepts.html)：截图对应的交互网页，可切换 SplitBehavior / DisplayMode，查看三栏布局与配置代码；独立文件，无需联网。
- [状态模型](Sources/RouteModel/RouteLedger.swift)：分别管理导航事务、布局版本和内容版本，防止旧回调恢复无效位置。
- [内容与选择校验](Sources/RouteModel/ReadingLibrary.swift)：验证文章存在且属于当前分类，删除后清空无效选择。
- [UIKit 完整示例](Examples/DefaultRouteHarness/TripleColumnDemoPackage/Sources/TripleColumnDemoFeature/DefaultRouteSplit.swift)：不设置独立 `.compact`，通过公开页面生命周期与转场协调器更新 route。
- [异步正文协调器](Sources/RouteModel/ArticleBodyLoader.swift)：用请求 ID、分类 / 文章 ID 和内容版本拒绝旧响应；取消请求不替代结果校验。
- [异步正文验证](Verification/异步正文验证.md)：快速切换、删除、分类变更、重复刷新及旧失败 / 取消的可控乱序测试。
- [内容失效验证](Verification/内容失效验证.md)：删除、分类变更与手势 / 布局的交错测试。
- [验证记录](Verification/交错场景验证.md)：模型测试、模拟器 UI 测试、失败修复记录及未覆盖范围。

## 运行示例

打开 `Examples/DefaultRouteHarness/TripleColumnDemo.xcworkspace`，选择 `TripleColumnDemo` scheme。选择 iPad 模拟器，用“自动 / 窄屏”切换环境；窄屏点击分类、文章后可使用系统 Back 按钮与边缘返回手势。

顶部状态展示选中文章、已提交 route、是否有未完成事务、是否正在恢复，以及交错计数。真实产品通常不需要这些诊断字段。

## 查看交互示意图

用浏览器打开 `Documentation/split-view-concepts.html`。在 macOS 的仓库根目录也可以运行：

```sh
open Documentation/split-view-concepts.html
```

图中固定 `Style = .tripleColumn` 和三个 Column，通过下拉框切换 SplitBehavior、DisplayMode，同时更新布局示意和 Swift 配置代码。页面支持浅色 / 深色外观及窄窗口。它是展开状态的教学示意，实际 UIKit 行为请运行上面的 iOS 示例。

## 测试

在仓库根目录运行 `swift test` 执行 25 项状态模型及正文竞态测试。UI 测试位于示例的 `TripleColumnDemoUITests`，在 Xcode 中运行 scheme 的测试即可。UI 测试外壳使用公开尺寸类别覆盖制造交错，不修改系统返回手势驱动器，也不直接伪造导航成功或取消。

## 更新阅读稿

修改模型、`ArticleBodyLoader.swift`、`DefaultRouteSplit.swift` 或正文测试后，运行：

```sh
python3 Scripts/update_annotations.py
```

脚本将当前模型和 UIKit 源码合并到注释版的第 22 节，同时同步第 23.1 节的异步正文测试，保持原始 SDK 声明不变，并把可编译副本写入 `/private/tmp/DefaultRouteSplit-delivery.swift`，用于部署目标检查。

此仓库的阅读稿承接原先 Codex 工作目录中的同名文件，之后以 `Documentation/UISplitViewController-中文注释.swift` 为准。
