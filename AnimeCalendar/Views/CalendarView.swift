//
//  CalendarView.swift
//  AnimeCalendar
//
//  折叠/展开式日历组件，Liquid Glass 风格
//

import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    /// 有番剧的星期几集合（0=周一, 6=周日）
    let daysWithAnime: Set<Int>

    @State private var isExpanded = false
    @State private var displayedMonth: Date

    private let cal = Calendar.current
    private static let weekAbbr = ["一", "二", "三", "四", "五", "六", "日"]

    init(selectedDate: Binding<Date>, daysWithAnime: Set<Int>) {
        self._selectedDate = selectedDate
        self.daysWithAnime = daysWithAnime
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 10) {
            headerRow
            weekdayLabels

            if isExpanded {
                monthGrid
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal:   .push(from: .bottom).combined(with: .opacity)
                    ))
            } else {
                weekStrip
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal:   .push(from: .top).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(duration: 0.38, bounce: 0.12), value: isExpanded)
        .onChange(of: isExpanded) { _, expanded in
            if expanded { displayedMonth = selectedDate }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            // 上月（仅展开时）
            if isExpanded {
                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .frame(width: 36, height: 36)
                }
                .tint(.primary)
            }

            Spacer(minLength: 0)

            Text(monthYearText)
                .font(.headline)
                .fontWeight(.semibold)
                .animation(nil, value: displayedMonth)

            Spacer(minLength: 0)

            // 下月（仅展开时）
            if isExpanded {
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .frame(width: 36, height: 36)
                }
                .tint(.primary)
            }

            // 展开/收起按钮
            Button {
                withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .fontWeight(.semibold)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(duration: 0.38), value: isExpanded)
                    .frame(width: 36, height: 36)
            }
            .tint(.primary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(Self.weekAbbr, id: \.self) { abbr in
                Text(abbr)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Week Strip（紧凑模式）

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(currentWeekDates, id: \.self) { date in
                dayCell(date: date)
            }
        }
    }

    // MARK: - Month Grid（展开模式）

    private var monthGrid: some View {
        let weeks = currentMonthWeeks
        return VStack(spacing: 2) {
            ForEach(0..<weeks.count, id: \.self) { wi in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { di in
                        if let date = weeks[wi][di] {
                            dayCell(date: date, dimIfOtherMonth: true)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(date: Date, dimIfOtherMonth: Bool = false) -> some View {
        let isSelected  = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday     = cal.isDateInToday(date)
        let isSameMonth = cal.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let dayIdx      = weekdayIndex(for: date)
        let hasAnime    = daysWithAnime.contains(dayIdx)
        let dimmed      = dimIfOtherMonth && !isSameMonth

        Button {
            withAnimation(.spring(duration: 0.22)) {
                selectedDate = date
                if isExpanded { displayedMonth = date }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    // 选中：填充圆
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 34, height: 34)
                    }
                    // 今天：描边圆（未选中时）
                    else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 1.5)
                            .frame(width: 34, height: 34)
                    }

                    Text(dayNumber(date))
                        .font(.callout)
                        .fontWeight(isToday || isSelected ? .bold : .regular)
                        .foregroundStyle(
                            isSelected ? Color.white :
                            dimmed      ? Color.secondary.opacity(0.4) :
                                          Color.primary
                        )
                }

                // 有番剧的指示点
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.85) : Color.accentColor)
                    .frame(width: 5, height: 5)
                    .opacity(hasAnime && !dimmed ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed helpers

    private var monthYearText: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh-CN")
        fmt.dateFormat = "yyyy年M月"
        return fmt.string(from: isExpanded ? displayedMonth : selectedDate)
    }

    private func dayNumber(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    private func weekdayIndex(for date: Date) -> Int {
        let wd = cal.component(.weekday, from: date)
        return (wd + 5) % 7   // 1=Sun→6, 2=Mon→0
    }

    /// 当前 selectedDate 所在周的 Mon–Sun
    private var currentWeekDates: [Date] {
        let wd = cal.component(.weekday, from: selectedDate)
        let offset = (wd + 5) % 7
        let monday = cal.date(byAdding: .day, value: -offset, to: selectedDate)!
        return (0...6).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    /// displayedMonth 对应月份的完整周数组（nil 表示本月外的占位）
    private var currentMonthWeeks: [[Date?]] {
        var comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else { return [] }

        let firstWD = cal.component(.weekday, from: firstDay)
        let startOffset = (firstWD + 5) % 7   // 让周一对齐第0列

        var dates: [Date?] = Array(repeating: nil, count: startOffset)
        for day in 1...range.count {
            dates.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        while dates.count % 7 != 0 { dates.append(nil) }

        return stride(from: 0, to: dates.count, by: 7).map { i in
            Array(dates[i..<min(i + 7, dates.count)])
        }
    }

    private func prevMonth() {
        withAnimation(.spring(duration: 0.3)) {
            displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }

    private func nextMonth() {
        withAnimation(.spring(duration: 0.3)) {
            displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
}

#Preview {
    CalendarView(
        selectedDate: .constant(Date()),
        daysWithAnime: [0, 2, 4, 6]   // 周一/三/五/日
    )
    .padding()
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    .padding()
}
