//
//  ScheduleView.swift
//  AnimeCalendar
//

import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Date()

    // 将所选日期映射为 0=周一…6=周日
    private var selectedDayIndex: Int {
        let wd = Calendar.current.component(.weekday, from: selectedDate)
        return (wd + 5) % 7
    }

    private var animeList: [Anime] {
        viewModel.animeForDay(at: selectedDayIndex)
    }

    private var daysWithAnime: Set<Int> {
        Set(viewModel.scheduleByDay.keys.filter {
            !(viewModel.scheduleByDay[$0]?.isEmpty ?? true)
        })
    }

    private var dayHeaderText: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh-CN")
        fmt.dateFormat = "M月d日"
        let names = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        return "\(fmt.string(from: selectedDate))  \(names[selectedDayIndex])"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        contentSection
                    } header: {
                        // 吸顶日历卡片
                        CalendarView(
                            selectedDate: $selectedDate,
                            daysWithAnime: daysWithAnime
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 22)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                        .background(Color(.systemBackground))  // 滚动时遮住下层内容
                    }
                }
            }
            .refreshable {
                await viewModel.loadAllSchedules()
            }
            .navigationTitle("番剧时间表")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadAllSchedulesWithErrorHandling()
        }
    }

    // MARK: - Content section

    @ViewBuilder
    private var contentSection: some View {
        // 日期 + 数量标题行
        HStack {
            Text(dayHeaderText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if !animeList.isEmpty {
                Text("\(animeList.count) 部")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)

        // 状态分支
        if viewModel.isLoading && viewModel.scheduleByDay.isEmpty {
            ProgressView("加载中…")
                .frame(maxWidth: .infinity)
                .padding(48)

        } else if let error = viewModel.errorMessage, viewModel.scheduleByDay.isEmpty {
            errorView(message: error)

        } else if animeList.isEmpty && !viewModel.isLoading {
            VStack(spacing: 12) {
                Image(systemName: "tv.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("该日暂无番剧播出")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(48)

        } else {
            animeListRows
        }
    }

    // MARK: - Anime list rows

    @ViewBuilder
    private var animeListRows: some View {
        VStack(spacing: 0) {
            ForEach(animeList) { anime in
                NavigationLink(destination: AnimeDetailView(anime: anime)) {
                    AnimeRowView(anime: anime)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                if anime.id != animeList.last?.id {
                    Divider()
                        .padding(.leading, 88)   // 缩进，跳过封面图宽度
                        .padding(.trailing, 16)
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Error view

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("重试") {
                Task { await viewModel.loadAllSchedulesWithErrorHandling() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
}

#Preview {
    ScheduleView()
}
