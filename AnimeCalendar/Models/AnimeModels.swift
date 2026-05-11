//
//  AnimeModels.swift
//  AnimeCalendar
//  TMDB-based data models
//

import Foundation

// MARK: - Supporting types

struct TMDBGenre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct TMDBNetwork: Codable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
    }
}

struct TMDBProductionCompany: Codable, Identifiable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct TMDBEpisode: Codable {
    let id: Int?
    let episodeNumber: Int?
    let seasonNumber: Int?
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
    }
}

// MARK: - Main model

/// 统一使用 TMDB 作为数据源，language=zh-CN 返回中文标题和简介
struct Anime: Codable, Identifiable {
    // 基础字段（列表和详情均有）
    let id: Int
    let name: String              // 中文标题
    let originalName: String?     // 日文原名
    let overview: String?         // 中文简介
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let firstAirDate: String?     // "YYYY-MM-DD"

    // 列表响应字段
    let genreIds: [Int]?

    // 详情响应字段（列表中为 nil）
    let genres: [TMDBGenre]?
    let status: String?
    let inProduction: Bool?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let nextEpisodeToAir: TMDBEpisode?
    let lastEpisodeToAir: TMDBEpisode?
    let networks: [TMDBNetwork]?
    let productionCompanies: [TMDBProductionCompany]?
    let episodeRunTime: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, status, networks, genres
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case firstAirDate = "first_air_date"
        case genreIds = "genre_ids"
        case inProduction = "in_production"
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case nextEpisodeToAir = "next_episode_to_air"
        case lastEpisodeToAir = "last_episode_to_air"
        case productionCompanies = "production_companies"
        case episodeRunTime = "episode_run_time"
    }

    // MARK: - 视图兼容的计算属性

    var displayTitle: String { name }
    var titleJapanese: String? { originalName }
    var score: Double? { voteAverage }
    var airing: Bool? { inProduction }

    var thumbnailURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }

    var largeThumbnailURL: URL? {
        if let path = backdropPath {
            return URL(string: "https://image.tmdb.org/t/p/original\(path)")
        }
        if let path = posterPath {
            return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
        }
        return nil
    }

    var year: Int? {
        guard let d = firstAirDate, d.count >= 4 else { return nil }
        return Int(d.prefix(4))
    }

    var genreNames: [String] {
        genres?.map(\.name) ?? []
    }

    /// 根据 nextEpisode / lastEpisode / firstAirDate 推算播出星期几（0=周一, 6=周日）
    var broadcastDayIndex: Int? {
        let dateStr = nextEpisodeToAir?.airDate
            ?? lastEpisodeToAir?.airDate
            ?? firstAirDate
        guard let dateStr else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return nil }
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday + 5) % 7   // 1=Sun→6, 2=Mon→0, ..., 7=Sat→5
    }

    var currentEpisodeNumber: Int? { lastEpisodeToAir?.episodeNumber }

    var episodeDisplay: String {
        if inProduction == true {
            if let current = currentEpisodeNumber {
                if let total = numberOfEpisodes, total > 0 {
                    return "更新至 \(current)/\(total) 集"
                }
                return "已更新 \(current) 集"
            }
            return "连载中"
        } else if let total = numberOfEpisodes, total > 0 {
            return "全 \(total) 集"
        }
        return "集数未知"
    }

    var episodeShortDisplay: String {
        if inProduction == true, let current = currentEpisodeNumber { return "\(current)" }
        if let total = numberOfEpisodes, total > 0 { return "\(total)" }
        return "?"
    }

    var episodeShortLabel: String {
        if inProduction == true, let current = currentEpisodeNumber {
            if let total = numberOfEpisodes, total > 0 { return "已更\(current)/共\(total)集" }
            return "已更新集数"
        }
        return "集数"
    }

    var cleanSynopsis: String? {
        let text = overview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    /// 下集播出日期文本，如"5月15日"
    var nextEpisodeDateText: String? {
        guard let dateStr = nextEpisodeToAir?.airDate else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return nil }
        let display = DateFormatter()
        display.dateFormat = "M月d日"
        return display.string(from: date)
    }

    var networkNames: String? {
        let names = networks?.map(\.name) ?? []
        return names.isEmpty ? nil : names.joined(separator: "  ·  ")
    }

    var studioNames: String? {
        let names = productionCompanies?.map(\.name) ?? []
        return names.isEmpty ? nil : names.joined(separator: "  ·  ")
    }

    var durationText: String? {
        guard let rt = episodeRunTime?.first, rt > 0 else { return nil }
        return "\(rt) 分钟"
    }
}

// MARK: - API response wrapper

struct TMDBDiscoverResponse: Codable {
    let page: Int
    let results: [Anime]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}
