from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'Documentation/UISplitViewController-中文注释.swift'
original = path.read_text()
model = (root / 'Sources/RouteModel/RouteLedger.swift').read_text() + '\n' + (root / 'Sources/RouteModel/ReadingLibrary.swift').read_text()
model += '\n' + (root / 'Sources/RouteModel/ArticleBodyLoader.swift').read_text()
ui = (root / 'Examples/DefaultRouteHarness/TripleColumnDemoPackage/Sources/TripleColumnDemoFeature/DefaultRouteSplit.swift').read_text().replace('import RouteModel\n', '')
code = 'import UIKit\n\n' + model + '\n' + ui.replace('import UIKit\n', '', 1)
section = (root / 'Documentation/默认折叠交错说明.txt').read_text()
section += ''.join('// ' + line if line.strip() else '//\n' for line in code.splitlines(keepends=True))
section += (root / 'Documentation/默认折叠交错测试.txt').read_text()
section += '// MARK: - 23.1 异步正文的可控乱序测试（独立 XCTest 文件）\n//\n'
section += '// 以下为仓库实际执行的完整测试；App 仅复制第 22 节，测试目标单独加入此节。\n'
section += '// 独立复制合并示例时，将 @testable import RouteModel 改成自己的 App 模块名。\n'
section += '// nextRequest 等待服务真正收到请求，deliver 等待响应已提交或丢弃；不依赖固定延迟。\n'
body_tests = (root / 'Tests/RouteModelTests/ArticleBodyTests.swift').read_text()
section += ''.join('// ' + line if line.strip() else '//\n' for line in body_tests.splitlines(keepends=True))
section += '//\n// UI 另用 --body-controlled 启用可控服务，点击分类 / 文章 / 重新加载与删除按钮，\n'
section += '// 手动让新请求先回、旧请求后回，检查真正显示的正文和 loading，不只断言状态计数。\n'
section += '// 覆盖快速切换、删除后重新折叠、切换分类及同文章刷新；结果见 Verification/异步正文验证.md。\n//\n'
start = original.index('// MARK: - 20.')
end = original.index('// MARK: - 24.')
result = original[:start] + section + original[end:]
def declarations(text):
    return ''.join(line for line in text.splitlines(keepends=True) if not line.lstrip().startswith('//'))
assert declarations(result) == declarations(original), '原始声明发生变化'
assert all(not line.endswith((' ', '\t')) for line in result.splitlines())
path.write_text(result)
# 供 iOS 15 可用性检查；放临时目录，不向交付目录写入编译产物。
Path('/private/tmp/DefaultRouteSplit-delivery.swift').write_text(code)
print(f'Updated {path}, {len(result.splitlines())} lines; declarations unchanged')
