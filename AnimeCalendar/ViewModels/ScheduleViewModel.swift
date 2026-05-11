//
//  ScheduleViewModel.swift
//  AnimeCalendar
//

import Foundation
import Observation

@Observable
class ScheduleViewModel {
    /// Cache keyed by the start-of-day Date
    private(set) var dailyCache: [Date: [AiringEntry]] = [:]

    var isLoading = false
    var errorMessage: String?

    /// Which weekday indices (0=Mon…6=Sun) have at least one cached entry
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

    /// Load schedule for `date`, skipping if already cached.
    func loadDay(_ date: Date) async {
        let key = startOfDay(date)
        guard dailyCache[key] == nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            let entries = try await AniListService.shared.fetchSchedule(for: date)
            dailyCache[key] = entries
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            dailyCache[key] = []
        }
        isLoading = false
    }

    /// Force-refresh `date` even if already cached.
    func forceReload(_ date: Date) async {
        let key = startOfDay(date)
        dailyCache.removeValue(forKey: key)
        await loadDay(date)
    }

    // MARK: - Helpers

    func todayIndex() -> Int {
        let wd = Calendar.current.component(.weekday, from: Date())
        return (wd + 5) % 7
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
