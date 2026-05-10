//
//  ScheduleViewModel.swift
//  AnimeCalendar
//

import Foundation
import Observation

@Observable
class ScheduleViewModel {
    var scheduleByDay: [String: [Anime]] = [:]
    var isLoading = false
    var errorMessage: String?

    let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    let dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    // Calendar.weekday: 1=Sun, 2=Mon, ..., 7=Sat → mapped to 0=Mon, ..., 6=Sun
    func todayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    func animeForDay(at index: Int) -> [Anime] {
        scheduleByDay[days[index]] ?? []
    }

    func loadAllSchedules() async {
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: (String, [Anime]).self) { group in
            for day in days {
                group.addTask {
                    let anime = (try? await JikanService.shared.fetchSchedule(for: day)) ?? []
                    return (day, anime)
                }
            }
            for await (day, anime) in group {
                scheduleByDay[day] = anime
            }
        }
        isLoading = false
    }

    func loadAllSchedulesWithErrorHandling() async {
        isLoading = true
        errorMessage = nil
        var firstError: String?
        var results: [String: [Anime]] = [:]
        await withTaskGroup(of: (String, Result<[Anime], Error>).self) { group in
            for day in days {
                group.addTask {
                    do {
                        let anime = try await JikanService.shared.fetchSchedule(for: day)
                        return (day, .success(anime))
                    } catch {
                        return (day, .failure(error))
                    }
                }
            }
            for await (day, result) in group {
                switch result {
                case .success(let anime):
                    results[day] = anime
                case .failure(let error):
                    if firstError == nil {
                        firstError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    }
                    results[day] = []
                }
            }
        }
        scheduleByDay = results
        errorMessage = firstError
        isLoading = false
    }
}
