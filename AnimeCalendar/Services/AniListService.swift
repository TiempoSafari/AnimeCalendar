//
//  AniListService.swift
//  AnimeCalendar
//

import Foundation

enum AniListError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:  return "无效的响应"
        case .httpError(let c): return "服务器错误（\(c)）"
        case .decodingError:    return "数据解析失败"
        }
    }
}

actor AniListService {
    static let shared = AniListService()
    private let endpoint = URL(string: "https://graphql.anilist.co")!

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 20
        cfg.timeoutIntervalForResource = 40
        return URLSession(configuration: cfg)
    }()

    // MARK: - Schedule

    /// Returns all airing entries for the calendar day containing `date` (user's local timezone).
    func fetchSchedule(for date: Date) async throws -> [AiringEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!

        let startTS = Int(start.timeIntervalSince1970)
        let endTS   = Int(end.timeIntervalSince1970)

        let query = """
        query($start: Int, $end: Int, $page: Int) {
          Page(page: $page, perPage: 50) {
            airingSchedules(airingAt_greater: $start, airingAt_lesser: $end,
                            sort: TIME) {
              id
              airingAt
              episode
              media {
                id
                title { romaji native english }
                description(asHtml: false)
                coverImage { large medium }
                bannerImage
                episodes
                status
                genres
                averageScore
                seasonYear
                synonyms
                isAdult
                studios(isMain: true) { nodes { name } }
                nextAiringEpisode { episode airingAt }
              }
            }
          }
        }
        """

        var all: [AiringEntry] = []
        var page = 1

        while true {
            let entries = try await executeScheduleQuery(
                query: query,
                variables: ["start": startTS - 1, "end": endTS, "page": page]
            )
            all.append(contentsOf: entries)
            if entries.count < 50 { break }
            page += 1
        }

        return all.filter { !($0.media.isAdult ?? false) }
    }

    // MARK: - Media detail

    func fetchMediaDetail(id: Int) async throws -> AniListMedia {
        let query = """
        query($id: Int) {
          Page(page: 1, perPage: 1) {
            media(id: $id, type: ANIME) {
              id
              title { romaji native english }
              description(asHtml: false)
              coverImage { large medium }
              bannerImage
              episodes
              status
              genres
              averageScore
              seasonYear
              synonyms
              isAdult
              studios(isMain: true) { nodes { name } }
              nextAiringEpisode { episode airingAt }
            }
          }
        }
        """

        let body: [String: Any] = ["query": query, "variables": ["id": id]]
        let data = try await post(body: body)
        do {
            return try JSONDecoder().decode(AniListPageResponse.self, from: data).data.Page.media!.first!
        } catch {
            throw AniListError.decodingError(error)
        }
    }

    // MARK: - Private helpers

    private func executeScheduleQuery(query: String, variables: [String: Any]) async throws -> [AiringEntry] {
        let body: [String: Any] = ["query": query, "variables": variables]
        let data = try await post(body: body)
        do {
            let response = try JSONDecoder().decode(AniListPageResponse.self, from: data)
            return response.data.Page.airingSchedules ?? []
        } catch {
            throw AniListError.decodingError(error)
        }
    }

    private func post(body: [String: Any]) async throws -> Data {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw AniListError.httpError(http.statusCode)
        }
        return data
    }
}
