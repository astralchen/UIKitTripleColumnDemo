import Foundation

// contentVersion 是本地内容上下文的代次，不是服务器 ETag，也不是 layoutVersion。
public struct ArticleBodyContext: Equatable, Sendable {
    public let categoryID: String
    public let articleID: String
    public let contentVersion: Int
    public init(categoryID: String, articleID: String, contentVersion: Int) {
        self.categoryID = categoryID; self.articleID = articleID; self.contentVersion = contentVersion
    }
}

public struct ArticleBodyRequest: Equatable, Sendable {
    public let id: UUID
    public let context: ArticleBodyContext
    public init(context: ArticleBodyContext) { id = UUID(); self.context = context }
}

public enum ArticleBodyState: Equatable, Sendable {
    case idle
    case loading(ArticleBodyRequest)
    case loaded(ArticleBodyRequest, String)
    case failed(ArticleBodyRequest, String)
}

public protocol ArticleBodyLoading: Sendable {
    func load(_ request: ArticleBodyRequest) async throws -> String
}

// 可直接运行的异步演示服务；接入后端时替换此协议实现，不改变提交结果的校验规则。
public struct DemoArticleBodyLoader: ArticleBodyLoading {
    public init() {}
    public func load(_ request: ArticleBodyRequest) async throws -> String {
        try await Task.sleep(nanoseconds: 150_000_000) // iOS 15 可用。
        return "正文：\(request.context.articleID)"
    }
}

@MainActor
public final class ArticleBodyCoordinator {
    public private(set) var state: ArticleBodyState = .idle
    public private(set) var context: ArticleBodyContext?
    public private(set) var activeRequest: ArticleBodyRequest?
    public var onChange: (() -> Void)?
    // 诊断 / 测试接点：收到响应且已完成接收或丢弃；不驱动路由。
    public var onResponseProcessed: ((ArticleBodyRequest, Bool) -> Void)?
    private let loader: any ArticleBodyLoading
    private var task: Task<Void, Never>?

    public init(loader: any ArticleBodyLoading = DemoArticleBodyLoader()) { self.loader = loader }
    deinit { task?.cancel() }

    // 删除 / 分类切换时，同步传 nil；不能等转场完成或再派发一轮主队列才作废请求。
    // route 与宽窄布局变化不改变 context，因此不会重复加载或清空仍然有效的正文。
    public func synchronize(context newContext: ArticleBodyContext?) {
        guard context != newContext else { return }
        context = newContext
        if newContext != nil { reload() }
        else {
            let oldTask = task
            activeRequest = nil; task = nil; state = .idle
            oldTask?.cancel() // 先撤销提交资格，再请求取消网络工作。
            onChange?()
        }
    }

    public func reload() {
        guard let context else { return }
        let request = ArticleBodyRequest(context: context) // 同文章重试也必须产生新 ID。
        let oldTask = task
        activeRequest = request
        state = .loading(request) // 立即移除上一文章正文，禁止标题 B 配正文 A。
        oldTask?.cancel()
        let service = loader
        task = Task { [weak self] in
            // 不在 await 前强持有 self，避免长请求把页面状态永久留住。
            let result: Result<String, Error>
            do { result = .success(try await service.load(request)) }
            catch { result = .failure(error) }
            self?.receive(result, for: request)
        }
        onChange?()
    }

    private func receive(_ result: Result<String, Error>, for request: ArticleBodyRequest) {
        // 所有成功、失败和取消都走同一扇门。检查与提交之间没有 await。
        guard activeRequest?.id == request.id, context == request.context else {
            onResponseProcessed?(request, false)
            return // 旧回调不能清空新 task / spinner，也不能弹出旧错误。
        }
        activeRequest = nil; task = nil
        switch result {
        case .success(let body): state = .loaded(request, body)
        case .failure(let error):
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                state = .idle // 当前请求主动结束，用户可显式重试。
            } else { state = .failed(request, error.localizedDescription) }
        }
        onChange?()
        onResponseProcessed?(request, true)
        // 不选中文章、不调用 show、不修改 route；正文到达并不代表用户重新进入详情。
    }
}
