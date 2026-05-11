//
//  TMDBService.swift
//  AnimeCalendar
//

import Foundation

actor TMDBService {
    static let shared = TMDBService()
    private let apiKey = "4a48edab5689570d724ea2e120507e79"
    private let baseURL = "https://api.themoviedb.org/3"

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 15
        cfg.timeoutIntervalForResource = 30
        return URLSession(configuration: cfg)
    }()

    struct ShowInfo: Codable {
        let id: Int
        let name: String
        let overview: String?

        enum CodingKeys: String, CodingKey {
            case id, name, overview
        }
    }

    /// Fetch Chinese-localized title and synopsis for a TMDB TV show ID.
    func fetchChineseInfo(id: Int) async throws -> ShowInfo {
        var comps = URLComponents(string: "\(baseURL)/tv/\(id)")!
        comps.queryItems = [
            .init(name: "api_key",  value: apiKey),
            .init(name: "language", value: "zh-CN"),
        ]
        guard let url = comps.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ShowInfo.self, from: data)
    }
}
