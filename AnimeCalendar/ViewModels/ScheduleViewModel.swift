//
//  ScheduleViewModel.swift
//  AnimeCalendar
//

import Foundation
import Observation

@Observable
class ScheduleViewModel {
    /// 按星期分组：0=周一, 1=周二, ..., 6=周日
    var scheduleByDay: [Int: [Anime]] = [:]
    var isLoading = false
    var errorMessage: String?

    let dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    // MARK: - Helpers

    /// 今天对应的 index（0=周一, 6=周日）
    func todayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    func animeForDay(at index: Int) -> [Anime] {
        scheduleByDay[index] ?? []
    }

    // MARK: - Data loading

    /// 拉取 3 页当季正在播出的日本动画，按播出星期分组。
    /// 出错时静默忽略（用于下拉刷新）。
    func loadAllSchedules() async {
        isLoading = true
        errorMessage = nil
        var all: [Anime] = []
        await withTaskGroup(of: [Anime].self) { group in
            for page in 1...3 {
                group.addTask {
                    (try? await TMDBService.shared.fetchAiringAnime(page: page)) ?? []
                }
            }
            for await shows in group { all.append(contentsOf: shows) }
        }
        scheduleByDay = groupByDay(all)
        isLoading = false
    }

    /// 拉取并上报第一个错误（用于初始加载）。
    func loadAllSchedulesWithErrorHandling() async {
        isLoading = true
        errorMessage = nil
        var all: [Anime] = []
        var firstError: String?
        await withTaskGroup(of: Result<[Anime], Error>.self) { group in
            for page in 1...3 {
                group.addTask {
                    do {
                        return .success(try await TMDBService.shared.fetchAiringAnime(page: page))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let shows):
                    all.append(contentsOf: shows)
                case .failure(let error):
                    if firstError == nil {
                        firstError = (error as? LocalizedError)?.errorDescription
                            ?? error.localizedDescription
                    }
                }
            }
        }
        scheduleByDay = groupByDay(all)
        errorMessage = all.isEmpty ? firstError : nil
        isLoading = false
    }

    // MARK: - Private

    private func groupByDay(_ shows: [Anime]) -> [Int: [Anime]] {
        var result: [Int: [Anime]] = [:]
        for show in shows {
            guard let day = show.broadcastDayIndex else { continue }
            result[day, default: []].append(show)
        }
        return result
    }
}
