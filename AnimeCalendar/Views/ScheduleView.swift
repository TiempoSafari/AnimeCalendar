//
//  ScheduleView.swift
//  AnimeCalendar
//

import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Date()

    private var selectedDayKey: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var selectedDayIndex: Int {
        let wd = Calendar.current.component(.weekday, from: selectedDate)
        return (wd + 5) % 7
    }

    private var entryList: [AiringEntry] {
        viewModel.entries(for: selectedDate)
    }

    private var daysWithAnime: Set<Int> { viewModel.daysWithAnime }

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
                        .background(Color(.systemBackground))
                    }
                }
            }
            .refreshable {
                await viewModel.forceReload(selectedDate)
            }
            .navigationTitle("番剧时间表")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: selectedDayKey) {
            await viewModel.loadDay(selectedDate)
        }
    }

    // MARK: - Content section

    @ViewBuilder
    private var contentSection: some View {
        HStack {
            Text(dayHeaderText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if !entryList.isEmpty {
                Text("\(entryList.count) 部")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)

        if viewModel.isLoading && !viewModel.isLoaded(for: selectedDate) {
            ProgressView("加载中…")
                .frame(maxWidth: .infinity)
                .padding(48)

        } else if let error = viewModel.errorMessage, entryList.isEmpty {
            errorView(message: error)

        } else if entryList.isEmpty && viewModel.isLoaded(for: selectedDate) {
            VStack(spacing: 12) {
                Image(systemName: "tv.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("该日暂无番剧更新")
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
            ForEach(entryList) { entry in
                NavigationLink(destination: AnimeDetailView(entry: entry)) {
                    AnimeRowView(entry: entry)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                if entry.id != entryList.last?.id {
                    Divider()
                        .padding(.leading, 136)
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
                Task { await viewModel.forceReload(selectedDate) }
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
