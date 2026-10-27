// 选择与当前数据源一同校验；不能只用 articleID != nil 判断详情有效。
public struct ReadingLibrary {
    public static let demoCatalog = ["UIKit": ["文章 A", "文章 B"], "Swift": ["Swift 文章 C", "Swift 文章 D"]]
    public private(set) var catalog: [String: [String]]
    public private(set) var categoryID: String?
    public private(set) var articleID: String?
    public var categoryIDs: [String] { catalog.keys.sorted(by: >) }
    public var articleIDs: [String] { categoryID.flatMap { catalog[$0] } ?? [] }

    public init(catalog: [String: [String]] = Self.demoCatalog,
                categoryID: String? = nil, articleID: String? = nil) {
        self.catalog = catalog; self.categoryID = categoryID; self.articleID = articleID
        normalizeSelection()
    }
    private mutating func normalizeSelection() {
        guard let categoryID, catalog[categoryID] != nil else {
            self.categoryID = nil; articleID = nil; return
        }
        if let articleID, !articleIDs.contains(articleID) { self.articleID = nil }
    }
    public func correctedRoute(_ route: ReadingPosition) -> ReadingPosition {
        guard categoryID != nil else { return .categories }
        if route == .detail && articleID == nil { return .list }
        return route // 已在分类页时，删除所选文章不强行把人带到列表。
    }
    @discardableResult
    public mutating func selectCategory(_ id: String) -> Bool {
        guard catalog[id] != nil, categoryID != id else { return false }
        categoryID = id; articleID = nil
        return true
    }
    @discardableResult
    public mutating func selectArticle(_ id: String) -> Bool {
        guard articleIDs.contains(id), articleID != id else { return false }
        articleID = id; return true
    }
    public mutating func deleteArticle(_ id: String, in category: String) {
        catalog[category]?.removeAll { $0 == id }
        normalizeSelection()
    }
    public mutating func deleteCategory(_ id: String) {
        catalog.removeValue(forKey: id)
        normalizeSelection()
    }
    public mutating func replaceCatalog(_ snapshot: [String: [String]]) {
        catalog = snapshot
        normalizeSelection() // 同 ID 重新出现不会自动恢复已清空的选择。
    }
}
