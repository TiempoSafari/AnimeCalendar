//
//  AnimeModels.swift
//  AnimeCalendar
//

import Foundation

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
    let episodes: Int?
    let score: Double?
    let images: AnimeImages?
    let broadcast: Broadcast?
    let genres: [Genre]?
    let studios: [Studio]?

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title
        case titleJapanese = "title_japanese"
        case episodes, score, images, broadcast, genres, studios
    }

    var id: Int { malId }

    var thumbnailURL: URL? {
        guard let urlString = images?.jpg?.imageUrl else { return nil }
        return URL(string: urlString)
    }

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
}

struct ScheduleResponse: Codable {
    let data: [Anime]
}
