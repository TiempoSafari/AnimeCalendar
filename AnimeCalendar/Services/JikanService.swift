//
//  JikanService.swift
//  AnimeCalendar
//

import Foundation

enum JikanError: LocalizedError {
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

actor JikanService {
    static let shared = JikanService()
    private let baseURL = "https://api.jikan.moe/v4"
    private let decoder = JSONDecoder()

    func fetchSchedule(for day: String) async throws -> [Anime] {
        guard let url = URL(string: "\(baseURL)/schedules?filter=\(day)&limit=25") else {
            throw JikanError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw JikanError.httpError(http.statusCode)
        }
        do {
            return try decoder.decode(ScheduleResponse.self, from: data).data
        } catch {
            throw JikanError.decodingError(error)
        }
    }

    func fetchAnimeDetail(id: Int) async throws -> Anime {
        guard let url = URL(string: "\(baseURL)/anime/\(id)") else {
            throw JikanError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw JikanError.httpError(http.statusCode)
        }
        struct SingleResponse: Codable { let data: Anime }
        do {
            return try decoder.decode(SingleResponse.self, from: data).data
        } catch {
            throw JikanError.decodingError(error)
        }
    }
}
