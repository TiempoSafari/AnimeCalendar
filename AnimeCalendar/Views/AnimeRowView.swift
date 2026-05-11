//
//  AnimeRowView.swift
//  AnimeCalendar
//

import SwiftUI

struct AnimeRowView: View {
    let anime: Anime

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 封面图
            AsyncImage(url: anime.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 信息区
            VStack(alignment: .leading, spacing: 5) {
                // 中文标题（主）
                Text(anime.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // 日文原名（副）
                if let japanese = anime.titleJapanese, !japanese.isEmpty,
                   japanese != anime.displayTitle {
                    Text(japanese)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    // 评分
                    if let score = anime.score, score > 0 {
                        Label(String(format: "%.1f", score), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    // 下集日期（详情拉取后才有）
                    if let nextDate = anime.nextEpisodeDateText {
                        Label(nextDate, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 集数状态（蓝色强调）
                Text(anime.episodeDisplay)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)

                // 类型标签
                if !anime.genreNames.isEmpty {
                    Text(anime.genreNames.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AnimeRowView(anime: Anime(
        id: 209867,
        name: "葬送的芙莉莲",
        originalName: "葬送のフリーレン",
        overview: "打倒魔王的勇者一行人，踏上了回归故乡的旅程……",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 8.7,
        firstAirDate: "2023-09-29",
        genreIds: [16],
        genres: [TMDBGenre(id: 16, name: "动画")],
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
    .padding()
}
