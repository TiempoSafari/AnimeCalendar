//
//  AniListModels.swift
//  AnimeCalendar
//

import Foundation

// MARK: - Airing Entry

struct AiringEntry: Codable, Identifiable {
    let id: Int
    let airingAt: Int       // Unix timestamp (UTC)
    let episode: Int
    let media: AniListMedia

    var airingDate: Date { Date(timeIntervalSince1970: TimeInterval(airingAt)) }

    var localTimeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        fmt.timeZone = .current
        return fmt.string(from: airingDate)
    }
}

// MARK: - Media

struct AniListMedia: Codable, Identifiable {
    let id: Int
    let title: AniListTitle
    let description: String?
    let coverImage: AniListCoverImage
    let bannerImage: String?
    let episodes: Int?
    let status: String?
    let genres: [String]?
    let averageScore: Int?
    let seasonYear: Int?
    let synonyms: [String]?
    let isAdult: Bool?
    let studios: AniListStudios?
    let nextAiringEpisode: AniListNextAiring?

    var displayTitle: String {
        if let cn = chineseTitle { return cn }
        return title.romaji ?? title.native ?? "未知标题"
    }

    var nativeTitle: String? { title.native }
    var romajiTitle: String? { title.romaji }

    var cleanSynopsis: String? {
        guard let desc = description else { return nil }
        // Strip HTML tags
        return desc
            .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var score: Double? {
        guard let s = averageScore, s > 0 else { return nil }
        return Double(s) / 10.0
    }

    var studioNames: String? {
        guard let nodes = studios?.nodes, !nodes.isEmpty else { return nil }
        return nodes.map(\.name).joined(separator: "、")
    }

    var coverURL: URL? { URL(string: coverImage.large ?? coverImage.medium ?? "") }
    var bannerURL: URL? {
        guard let b = bannerImage else { return nil }
        return URL(string: b)
    }

    var genreNames: [String] { genres ?? [] }

    // MARK: - Private helpers

    private var chineseTitle: String? {
        guard let synonyms else { return nil }
        return synonyms.first { isChinese($0) }
    }

    private func isChinese(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        let hasCJK = s.unicodeScalars.contains {
            ($0.value >= 0x4E00 && $0.value <= 0x9FFF) ||
            ($0.value >= 0x3400 && $0.value <= 0x4DBF)
        }
        let hasKana = s.unicodeScalars.contains {
            ($0.value >= 0x3040 && $0.value <= 0x30FF)  // hiragana + katakana
        }
        return hasCJK && !hasKana
    }
}

struct AniListTitle: Codable {
    let romaji: String?
    let native: String?
    let english: String?
}

struct AniListCoverImage: Codable {
    let large: String?
    let medium: String?
}

struct AniListStudios: Codable {
    let nodes: [AniListStudio]?
}

struct AniListStudio: Codable {
    let name: String
}

struct AniListNextAiring: Codable {
    let episode: Int
    let airingAt: Int
}

// MARK: - GraphQL response wrappers

struct AniListPageResponse: Codable {
    let data: AniListDataWrapper
}

struct AniListDataWrapper: Codable {
    let Page: AniListPage
}

struct AniListPage: Codable {
    let airingSchedules: [AiringEntry]?
    let media: [AniListMedia]?
}
