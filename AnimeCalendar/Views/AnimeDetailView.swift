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
                            ProgressView()
                                .padding(.trailing, 6)
                            Text("加载详情中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }

                    if let studios = displayAnime.studios, !studios.isEmpty {
                        studiosRow(studios: studios)
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
            fullAnime = try? await JikanService.shared.fetchAnimeDetail(id: anime.malId)
            isLoadingDetail = false
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图片
            AsyncImage(url: displayAnime.largeThumbnailURL ?? displayAnime.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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

            // 渐变遮罩
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

            // 文字信息叠层
            VStack(alignment: .leading, spacing: 6) {
                Text(displayAnime.displayTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let japanese = displayAnime.titleJapanese, !japanese.isEmpty {
                    Text(japanese)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // 年份 · 类型 · 状态
                HStack(spacing: 5) {
                    if let year = displayAnime.year {
                        Text("\(String(year))年")
                    }
                    if let type = displayAnime.type, !type.isEmpty {
                        Text("·")
                        Text(type)
                    }
                    if displayAnime.airing == true {
                        Text("·")
                        Text("连载中")
                            .foregroundStyle(.green)
                    } else {
                        Text("·")
                        Text("已完结")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // 类型标签
                if let genres = displayAnime.genres, !genres.isEmpty {
                    Text(genres.prefix(4).map(\.name).joined(separator: "，"))
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
            circleActionButton(icon: "safari", label: "探索")
            circleActionButton(icon: "square.and.arrow.up", label: "分享")
            circleActionButton(icon: "heart", label: "收藏")
            circleActionButton(icon: "ellipsis", label: "更多")
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
                    icon: "star.fill",
                    iconColor: .blue,
                    value: String(format: "%.1f", score),
                    label: "MAL 评分"
                )
            }

            AnimeStatCard(
                icon: "play.rectangle.fill",
                iconColor: .blue,
                value: displayAnime.episodeShortDisplay,
                label: displayAnime.episodeShortLabel
            )

            let time = displayAnime.localBroadcastTime
            if time != "时间未知" {
                AnimeStatCard(
                    icon: "clock.fill",
                    iconColor: .blue,
                    value: time,
                    label: "播出时间"
                )
            }
        }
    }

    // MARK: - Studios

    @ViewBuilder
    private func studiosRow(studios: [Studio]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("制作公司", systemImage: "building.2")
                .font(.headline)
            Text(studios.map(\.name).joined(separator: "  ·  "))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Synopsis

    @ViewBuilder
    private func synopsisCard(synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("简介")
                .font(.headline)
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
            malId: 52991,
            title: "Sousou no Frieren",
            titleJapanese: "葬送のフリーレン",
            titles: [AnimeTitle(type: "English", title: "Frieren: Beyond Journey's End")],
            episodes: 28,
            score: 9.3,
            images: AnimeImages(jpg: AnimeImage(imageUrl: nil, largeImageUrl: nil)),
            broadcast: Broadcast(day: "Fridays", time: "23:00", timezone: "Asia/Tokyo"),
            genres: [Genre(malId: 1, name: "Adventure"), Genre(malId: 2, name: "Drama")],
            studios: [Studio(malId: 1, name: "Madhouse")],
            synopsis: "After the party of heroes defeated the Demon King, they finally return to their hometown.",
            aired: AiredDate(from: "2023-09-29T00:00:00+00:00", to: "2024-03-22T00:00:00+00:00"),
            duration: "24 min per ep",
            airing: false,
            type: "TV",
            year: 2023
        ))
    }
}
