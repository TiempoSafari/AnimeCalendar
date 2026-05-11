//
//  AnimeDetailView.swift
//  AnimeCalendar
//

import SwiftUI

struct AnimeDetailView: View {
    let entry: AiringEntry
    var viewModel: ScheduleViewModel?

    @State private var fullMedia: AniListMedia?
    @State private var chineseInfo: TMDBService.ShowInfo?
    @State private var isLoadingDetail = false

    private var media: AniListMedia { fullMedia ?? entry.media }
    private var chineseTitle: String {
        chineseInfo?.name
            ?? viewModel?.chineseCache[entry.media.id]?.name
            ?? media.displayTitle
    }
    private var chineseSynopsis: String? {
        chineseInfo?.overview
            ?? viewModel?.chineseCache[entry.media.id]?.overview
            ?? media.cleanSynopsis
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                VStack(alignment: .leading, spacing: 16) {
                    actionButtonsRow
                    statsCardsRow

                    if isLoadingDetail && fullMedia == nil {
                        HStack {
                            ProgressView().padding(.trailing, 6)
                            Text("加载详情中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }

                    if let studio = media.studioNames {
                        infoCard(icon: "building.2", title: "制作公司", content: studio)
                    }

                    if let synopsis = chineseSynopsis, !synopsis.isEmpty {
                        synopsisCard(synopsis: synopsis)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            isLoadingDetail = true
            let detail = try? await AniListService.shared.fetchMediaDetail(id: entry.media.id)
            fullMedia = detail
            let tmdbId = detail?.tmdbId ?? entry.media.tmdbId
            if let tmdbId {
                chineseInfo = try? await TMDBService.shared.fetchChineseInfo(id: tmdbId)
            }
            isLoadingDetail = false
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            let imageURL = media.bannerURL ?? media.coverURL

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        )
                default:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .clipped()

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.30),
                    .init(color: Color(.systemBackground).opacity(0.85), location: 0.72),
                    .init(color: Color(.systemBackground), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 420)

            VStack(alignment: .leading, spacing: 6) {
                Text(chineseTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let native = media.nativeTitle,
                   !native.isEmpty, native != chineseTitle {
                    Text(native)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 5) {
                    if let year = media.seasonYear {
                        Text("\(String(year))年")
                    }
                    if let status = media.status {
                        Text("·")
                        Text(localizedStatus(status))
                            .foregroundStyle(status == "RELEASING" ? .green : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !media.genreNames.isEmpty {
                    Text(media.genreNames.prefix(4).joined(separator: "，"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtonsRow: some View {
        HStack(spacing: 0) {
            circleActionButton(icon: "safari",               label: "探索")
            circleActionButton(icon: "square.and.arrow.up",  label: "分享")
            circleActionButton(icon: "heart",                label: "收藏")
            circleActionButton(icon: "ellipsis",             label: "更多")
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func circleActionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 54, height: 54)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Cards

    @ViewBuilder
    private var statsCardsRow: some View {
        HStack(spacing: 12) {
            if let score = media.score {
                AnimeStatCard(
                    icon: "star.fill", iconColor: .blue,
                    value: String(format: "%.1f", score),
                    label: "AniList 评分"
                )
            }

            AnimeStatCard(
                icon: "clock.fill", iconColor: .blue,
                value: entry.localTimeString,
                label: "播出时间"
            )

            AnimeStatCard(
                icon: "play.rectangle.fill", iconColor: .blue,
                value: "第\(entry.episode)集",
                label: episodeLabel
            )
        }
    }

    private var episodeLabel: String {
        if let total = media.episodes, total > 0 {
            return "共\(total)集"
        }
        return "本次更新"
    }

    // MARK: - Info Cards

    @ViewBuilder
    private func infoCard(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.headline)
            Text(content)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func synopsisCard(synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("简介").font(.headline)
            Text(synopsis)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "RELEASING":    return "连载中"
        case "FINISHED":     return "已完结"
        case "NOT_YET_AIRED": return "未开播"
        case "CANCELLED":    return "已取消"
        case "HIATUS":       return "暂停更新"
        default:             return status
        }
    }
}

// MARK: - Stat Card Component

struct AnimeStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        AnimeDetailView(entry: AiringEntry(
            id: 1,
            airingAt: Int(Date().timeIntervalSince1970),
            episode: 5,
            media: AniListMedia(
                id: 21,
                title: AniListTitle(romaji: "Frieren: Beyond Journey's End", native: "葬送のフリーレン", english: nil),
                description: "打倒魔王的勇者一行人，踏上了回归故乡的旅程。在旅途中精灵魔法师芙莉莲和勇者辉美……",
                coverImage: AniListCoverImage(large: nil, medium: nil),
                bannerImage: nil,
                episodes: 28,
                status: "FINISHED",
                genres: ["Adventure", "Drama", "Fantasy"],
                averageScore: 87,
                seasonYear: 2023,
                synonyms: ["葬送的芙莉莲"],
                isAdult: false,
                studios: AniListStudios(nodes: [AniListStudio(name: "Madhouse")]),
                nextAiringEpisode: nil,
                externalLinks: nil
            )
        ))
    }
}
