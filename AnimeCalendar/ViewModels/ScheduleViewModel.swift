//
//  ScheduleViewModel.swift
//  AnimeCalendar
//

import Foundation
import Observation

@Observable
class ScheduleViewModel {
    private(set) var dailyCache: [Date: [AiringEntry]] = [:]
    /// Keyed by AniList media ID → TMDB zh-CN title + synopsis
    private(set) var chineseCache: [Int: TMDBService.ShowInfo] = [:]

    var isLoading = false
    var errorMessage: String?

    var daysWithAnime: Set<Int> {
        var result = Set<Int>()
        for (date, entries) in dailyCache where !entries.isEmpty {
            let wd = Calendar.current.component(.weekday, from: date)
            result.insert((wd + 5) % 7)
        }
        return result
    }

    // MARK: - Queries

    func entries(for date: Date) -> [AiringEntry] {
        dailyCache[startOfDay(date)] ?? []
    }

    func isLoaded(for date: Date) -> Bool {
        dailyCache[startOfDay(date)] != nil
    }

    func chineseTitle(for entry: AiringEntry) -> String {
        chineseCache[entry.media.id]?.name ?? entry.media.displayTitle
    }

    func chineseSynopsis(for mediaId: Int, fallback: String?) -> String? {
        chineseCache[mediaId]?.overview ?? fallback
    }

    // MARK: - Loading

    func loadDay(_ date: Date) async {
        let key = startOfDay(date)
        guard dailyCache[key] == nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await AniListService.shared.fetchSchedule(for: date)
            dailyCache[key] = fetched
            isLoading = false
            // Background: fetch TMDB Chinese data for entries that have a TMDB ID
            Task { await fetchChineseData(for: fetched) }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            dailyCache[key] = []
            isLoading = false
        }
    }

    func forceReload(_ date: Date) async {
        let key = startOfDay(date)
        dailyCache.removeValue(forKey: key)
        await loadDay(date)
    }

    // MARK: - Private

    private func fetchChineseData(for entries: [AiringEntry]) async {
        let needsFetch = entries.filter {
            chineseCache[$0.media.id] == nil && $0.media.tmdbId != nil
        }
        guard !needsFetch.isEmpty else { return }

        await withTaskGroup(of: (Int, TMDBService.ShowInfo?).self) { group in
            for entry in needsFetch {
                guard let tmdbId = entry.media.tmdbId else { continue }
                let mediaId = entry.media.id
                group.addTask {
                    let info = try? await TMDBService.shared.fetchChineseInfo(id: tmdbId)
                    return (mediaId, info)
                }
            }
            for await (mediaId, info) in group {
                if let info { chineseCache[mediaId] = info }
            }
        }
    }

    func todayIndex() -> Int {
        let wd = Calendar.current.component(.weekday, from: Date())
        return (wd + 5) % 7
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
