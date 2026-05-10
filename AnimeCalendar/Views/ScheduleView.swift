//
//  ScheduleView.swift
//  AnimeCalendar
//

import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedDayIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("选择日期", selection: $selectedDayIndex) {
                    ForEach(viewModel.dayNames.indices, id: \.self) { index in
                        Text(viewModel.dayNames[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if viewModel.isLoading && viewModel.scheduleByDay.isEmpty {
                    Spacer()
                    ProgressView("加载中...")
                        .progressViewStyle(.circular)
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.scheduleByDay.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("重试") {
                            Task { await viewModel.loadAllSchedulesWithErrorHandling() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    let animeList = viewModel.animeForDay(at: selectedDayIndex)
                    if animeList.isEmpty && !viewModel.isLoading {
                        Spacer()
                        ContentUnavailableView(
                            "暂无番剧信息",
                            systemImage: "tv.slash",
                            description: Text("该日暂无番剧播出记录")
                        )
                        Spacer()
                    } else {
                        List(animeList) { anime in
                            AnimeRowView(anime: anime)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadAllSchedules()
                        }
                    }
                }
            }
            .navigationTitle("番剧时间表")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            selectedDayIndex = viewModel.todayIndex()
            await viewModel.loadAllSchedulesWithErrorHandling()
        }
    }
}

#Preview {
    ScheduleView()
}
