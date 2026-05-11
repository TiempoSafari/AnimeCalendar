//
//  AnimeDetailView.swift
//  AnimeCalendar
//

import SwiftUI

struct AnimeDetailView: View {
    let anime: Anime

    @State private var fullAnime: Anime?
    @State private var isLoadingDetail = false

    private var displayAnime: Anime { fullAnime ?? anime }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                VStack(alignment: .leading, spacing: 16) {
                    actionButtonsRow
                    statsCardsRow

                    if isLoadingDetail && fullAnime == nil {
                        HStack {
                            ProgressView().padding(.trailing, 6)
                            Text("加载详情中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }

                    if let net = displayAnime.networkNames {
                        infoCard(icon: "play.tv", title: "播出平台", content: net)
                    }

                    if let studio = displayAnime.studioNames {
                        infoCard(icon: "building.2", title: "制作公司", content: studio)
                    }

                    if let synopsis = displayAnime.cleanSynopsis, !synopsis.isEmpty {
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
            fullAnime = try? await TMDBService.shared.fetchShowDetail(id: anime.id)
            isLoadingDetail = false
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: displayAnime.largeThumbnailURL ?? displayAnime.thumbnailURL) { phase in
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
                Text(displayAnime.displayTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let japanese = displayAnime.titleJapanese,
                   !japanese.isEmpty, japanese != displayAnime.displayTitle {
                    Text(japanese)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 5) {
                    if let year = displayAnime.year {
                        Text("\(String(year))年")
                    }
                    Text("·")
                    if displayAnime.airing == true {
                        Text("连载中").foregroundStyle(.green)
                    } else {
                        Text("已完结")
                    }
                    if let seasons = displayAnime.numberOfSeasons, seasons > 1 {
                        Text("·")
                        Text("\(seasons) 季")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !displayAnime.genreNames.isEmpty {
                    Text(displayAnime.genreNames.prefix(4).joined(separator: "，"))
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
            circleActionButton(icon: "safari",                label: "探索")
            circleActionButton(icon: "square.and.arrow.up",   label: "分享")
            circleActionButton(icon: "heart",                 label: "收藏")
            circleActionButton(icon: "ellipsis",              label: "更多")
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
            if let score = displayAnime.score, score > 0 {
                AnimeStatCard(
                    icon: "star.fill", iconColor: .blue,
                    value: String(format: "%.1f", score),
                    label: "TMDB 评分"
                )
            }

            AnimeStatCard(
                icon: "play.rectangle.fill", iconColor: .blue,
                value: displayAnime.episodeShortDisplay,
                label: displayAnime.episodeShortLabel
            )

            // 优先显示下集日期，其次时长
            if let nextDate = displayAnime.nextEpisodeDateText {
                AnimeStatCard(
                    icon: "calendar.badge.clock", iconColor: .blue,
                    value: nextDate,
                    label: "下集播出"
                )
            } else if let duration = displayAnime.durationText {
                AnimeStatCard(
                    icon: "clock.fill", iconColor: .blue,
                    value: duration,
                    label: "每集时长"
                )
            }
        }
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
        AnimeDetailView(anime: Anime(
            id: 209867,
            name: "葬送的芙莉莲",
            originalName: "葬送のフリーレン",
            overview: "打倒魔王的勇者一行人，踏上了回归故乡的旅程。在旅途中精灵魔法师芙莉莲和勇者辉美，在旅程终点的王都里，和彼此相知相惜",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 8.7,
            firstAirDate: "2023-09-29",
            genreIds: nil,
            genres: [TMDBGenre(id: 16, name: "动画"), TMDBGenre(id: 18, name: "剧情")],
            status: "Ended",
            inProduction: false,
            numberOfEpisodes: 28,
            numberOfSeasons: 1,
            nextEpisodeToAir: nil,
            lastEpisodeToAir: TMDBEpisode(id: 1, episodeNumber: 28, seasonNumber: 1, airDate: "2024-03-22"),
            networks: [TMDBNetwork(id: 1, name: "NTV", logoPath: nil)],
            productionCompanies: [TMDBProductionCompany(id: 1, name: "Madhouse")],
            episodeRunTime: [24]
        ))
    }
}
