import Foundation

public enum WanderQuery {
    /// Keep the original English command available in every language.
    public static func recallQuery(in query: String) -> String? {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["find ", "查找", "搜索", "尋找", "搜尋", "検索", "探す", "buscar ", "cari "]
        guard let prefix = prefixes.first(where: { text.lowercased().hasPrefix($0) }) else { return nil }
        let result = text.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ":：")))
        return result.isEmpty ? nil : result
    }

    static func requestsLocalizedExplanation(_ query: String) -> Bool {
        let subjectFirstPattern = #"(?:を(?:説明|解説)して|について(?:教えて|説明|解説)|とは(?:何|なに)|って(?:何|なに)|は(?:なぜ|どうして)|(?:是什么|是什麼)[？?]?$)"#
        if query.range(of: subjectFirstPattern, options: .regularExpression) != nil { return true }
        let pattern = #"^(?:(?:请|請)?(?:解释|解釋|说明|說明|举例|舉例|给我|給我)|什么是|什麼是|为什么|為什麼|如何|どうして|なぜ|説明|解説|教えて|例を|(?:por favor\s+)?(?:explica|expl[ií]came|define|ens[eé][nñ]ame|qu[eé] es|qu[eé] son|por qu[eé]|c[oó]mo funciona|dame un ejemplo)\b|(?:tolong\s+)?(?:jelaskan|terangkan|apa itu|mengapa|kenapa|bagaimana|beri contoh|berikan contoh)\b)"#
        return query.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "¿¡")))
            .range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
