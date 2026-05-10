//
//  AnimeRowView.swift
//  AnimeCalendar
//

import SwiftUI

struct AnimeRowView: View {
    let anime: Anime

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: anime.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: 6)
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
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.headline)
                    .lineLimit(2)

                if let japanese = anime.titleJapanese, !japanese.isEmpty {
                    Text(japanese)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    let broadcastTime = anime.localBroadcastTime
                    if broadcastTime != "时间未知" {
                        Label(broadcastTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let score = anime.score, score > 0 {
                        Label(String(format: "%.1f", score), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let episodes = anime.episodes {
                    Text("全\(episodes)集")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

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
        malId: 1,
        title: "鬼灭之刃",
        titleJapanese: "鬼滅の刃",
        episodes: 26,
        score: 8.7,
        images: AnimeImages(jpg: AnimeImage(imageUrl: nil, largeImageUrl: nil)),
        broadcast: Broadcast(day: "Sundays", time: "23:15", timezone: "Asia/Tokyo"),
        genres: [Genre(malId: 1, name: "Action"), Genre(malId: 2, name: "Fantasy")],
        studios: [Studio(malId: 1, name: "ufotable")]
    ))
    .padding()
}
