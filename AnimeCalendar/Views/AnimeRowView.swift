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
                // 英文标题（主标题）
                Text(anime.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // 日文标题（副标题）
                if let japanese = anime.titleJapanese, !japanese.isEmpty {
                    Text(japanese)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    // 播出时间
                    let broadcastTime = anime.localBroadcastTime
                    if broadcastTime != "时间未知" {
                        Label(broadcastTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    // 评分
                    if let score = anime.score, score > 0 {
                        Label(String(format: "%.1f", score), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // 集数状态（蓝色强调）
                Text(anime.episodeDisplay)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)

                // 类型标签
                if let genres = anime.genres, !genres.isEmpty {
                    Text(genres.prefix(3).map(\.name).joined(separator: " · "))
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
        malId: 52991,
        title: "Sousou no Frieren",
        titleJapanese: "葬送のフリーレン",
        titles: [
            AnimeTitle(type: "English", title: "Frieren: Beyond Journey's End"),
            AnimeTitle(type: "Japanese", title: "葬送のフリーレン")
        ],
        episodes: 28,
        score: 9.3,
        images: AnimeImages(jpg: AnimeImage(imageUrl: nil, largeImageUrl: nil)),
        broadcast: Broadcast(day: "Fridays", time: "23:00", timezone: "Asia/Tokyo"),
        genres: [Genre(malId: 1, name: "Adventure"), Genre(malId: 2, name: "Drama")],
        studios: [Studio(malId: 1, name: "Madhouse")],
        synopsis: nil,
        aired: AiredDate(from: "2023-09-29T00:00:00+00:00", to: nil),
        duration: "24 min per ep",
        airing: false,
        type: "TV",
        year: 2023
    ))
    .padding()
}
