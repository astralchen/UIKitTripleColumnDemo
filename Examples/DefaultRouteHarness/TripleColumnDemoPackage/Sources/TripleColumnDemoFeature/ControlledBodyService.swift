import UIKit
import RouteModel

// 仅由 --body-controlled 启用的验证服务。故意忽略取消，允许旧请求继续返回。
@MainActor
final class ControlledBodyService: ArticleBodyLoading {
    private var pending: [(ArticleBodyRequest, CheckedContinuation<String, Error>)] = []
    var onCountChange: ((Int) -> Void)?
    func load(_ request: ArticleBodyRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            pending.append((request, continuation))
            onCountChange?(pending.count)
        }
    }
    func release(newest: Bool) {
        guard !pending.isEmpty else { return }
        let (request, continuation) = pending.remove(at: newest ? pending.count - 1 : 0)
        continuation.resume(returning: "正文：\(request.context.articleID) · \(newest ? "新响应" : "旧响应")")
        onCountChange?(pending.count)
    }
}
