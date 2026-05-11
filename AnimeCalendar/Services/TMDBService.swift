//
//  TMDBService.swift
//  AnimeCalendar
//

import Foundation

enum TMDBError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .httpError(let code):
            return "服务器错误（\(code)）"
        case .decodingError:
            return "数据解析失败"
        }
    }
}

actor TMDBService {
    static let shared = TMDBService()

    private let apiKey = "4a48edab5689570d724ea2e120507e79"
    private let baseURL = "https://api.themoviedb.org/3"
    private let decoder = JSONDecoder()

    /// 获取正在播出的日本动画（分页，language=zh-CN）
    func fetchAiringAnime(page: Int = 1) async throws -> [Anime] {
        var comps = URLComponents(string: "\(baseURL)/discover/tv")!
        comps.queryItems = [
            .init(name: "api_key",            value: apiKey),
            .init(name: "language",           value: "zh-CN"),
            .init(name: "with_genres",        value: "16"),       // Animation
            .init(name: "with_origin_country",value: "JP"),
            .init(name: "with_status",        value: "0"),        // Returning Series
            .init(name: "sort_by",            value: "popularity.desc"),
            .init(name: "page",               value: "\(page)"),
        ]
        guard let url = comps.url else { throw TMDBError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw TMDBError.httpError(http.statusCode)
        }
        do {
            return try decoder.decode(TMDBDiscoverResponse.self, from: data).results
        } catch {
            throw TMDBError.decodingError(error)
        }
    }

    /// 获取单部剧集完整详情（含 genres、networks、集数、简介等）
    func fetchShowDetail(id: Int) async throws -> Anime {
        var comps = URLComponents(string: "\(baseURL)/tv/\(id)")!
        comps.queryItems = [
            .init(name: "api_key",  value: apiKey),
            .init(name: "language", value: "zh-CN"),
        ]
        guard let url = comps.url else { throw TMDBError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw TMDBError.httpError(http.statusCode)
        }
        do {
            return try decoder.decode(Anime.self, from: data)
        } catch {
            throw TMDBError.decodingError(error)
        }
    }
}
