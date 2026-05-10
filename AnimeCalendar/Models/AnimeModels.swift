//
//  AnimeModels.swift
//  AnimeCalendar
//

import Foundation

struct AnimeTitle: Codable {
    let type: String
    let title: String
}

struct AnimeImage: Codable {
    let imageUrl: String?
    let largeImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case largeImageUrl = "large_image_url"
    }
}

struct AnimeImages: Codable {
    let jpg: AnimeImage?
}

struct Broadcast: Codable {
    let day: String?
    let time: String?
    let timezone: String?
}

struct AiredDate: Codable {
    let from: String?
    let to: String?
}

struct Genre: Codable, Identifiable {
    let malId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
    }

    var id: Int { malId }
}

struct Studio: Codable, Identifiable {
    let malId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
    }

    var id: Int { malId }
}

struct Anime: Codable, Identifiable {
    let malId: Int
    let title: String
    let titleJapanese: String?
    let titles: [AnimeTitle]?
    let episodes: Int?
    let score: Double?
    let images: AnimeImages?
    let broadcast: Broadcast?
    let genres: [Genre]?
    let studios: [Studio]?
    let synopsis: String?
    let aired: AiredDate?
    let duration: String?
    let airing: Bool?
    let type: String?
    let year: Int?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title
        case titleJapanese = "title_japanese"
        case titles, episodes, score, images, broadcast, genres, studios
        case synopsis, aired, duration, airing, type, year
    }

    var id: Int { malId }

    // MARK: - Display helpers

    /// 优先英文标题，其次默认标题（罗马音）
    var displayTitle: String {
        titles?.first(where: { $0.type == "English" })?.title ?? title
    }

    var thumbnailURL: URL? {
        guard let str = images?.jpg?.imageUrl, !str.isEmpty else { return nil }
        return URL(string: str)
    }

    var largeThumbnailURL: URL? {
        guard let str = images?.jpg?.largeImageUrl ?? images?.jpg?.imageUrl, !str.isEmpty else { return nil }
        return URL(string: str)
    }

    /// 将播出时间从源时区转换为本地时区（HH:mm）
    var localBroadcastTime: String {
        guard let time = broadcast?.time,
              let tz = broadcast?.timezone,
              let zone = TimeZone(identifier: tz) else { return "时间未知" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = zone
        guard let date = formatter.date(from: time) else { return time }
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    /// 根据开播日期估算当前已播集数（假设每周一集）
    var estimatedCurrentEpisode: Int? {
        guard let fromStr = aired?.from else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        guard let startDate = f1.date(from: fromStr) ?? f2.date(from: fromStr),
              startDate <= Date() else { return nil }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: Date()).weekOfYear ?? 0
        let estimated = weeks + 1
        if let total = episodes { return min(estimated, total) }
        return estimated
    }

    /// 集数状态描述（如"更新至 12/24 集"或"全 24 集"）
    var episodeDisplay: String {
        if airing == true {
            if let current = estimatedCurrentEpisode {
                if let total = episodes { return "更新至 \(current)/\(total) 集" }
                return "已更新 \(current) 集"
            }
            return "连载中"
        } else if let total = episodes {
            return "全 \(total) 集"
        }
        return "集数未知"
    }

    /// 简短集数文字（用于详情页统计卡片）
    var episodeShortDisplay: String {
        if airing == true, let current = estimatedCurrentEpisode {
            return "\(current)"
        }
        if let total = episodes { return "\(total)" }
        return "?"
    }

    var episodeShortLabel: String {
        if airing == true, let current = estimatedCurrentEpisode {
            if let total = episodes { return "已更\(current)/共\(total)集" }
            return "已更新集数"
        }
        return "集数"
    }

    /// 去除 MAL 来源标注的简介
    var cleanSynopsis: String? {
        synopsis?
            .replacingOccurrences(of: "\n\n[Written by MAL Rewrite]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ScheduleResponse: Codable {
    let data: [Anime]
}
