# 示例维护约定

- 使用纯 UIKit、程序化布局及中文注释。
- 最低 iOS 15；iOS 26 API 必须有可用性保护。
- App target 只负责 UIKit 生命周期；主要示例放在本地 Swift Package。
- 修改折叠、展开或 inspector 时运行对应 UI 测试。
