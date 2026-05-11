//
//  AnimeRowView.swift
//  AnimeCalendar
//

import SwiftUI

struct AnimeRowView: View {
    let entry: AiringEntry
    /// TMDB zh-CN title override; falls back to AniList displayTitle when nil
    var chineseTitle: String?

    private var media: AniListMedia { entry.media }
    private var title: String { chineseTitle ?? media.displayTitle }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 播出时间（左侧时间列）
            VStack(spacing: 2) {
                Text(entry.localTimeString)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text("第\(entry.episode)集")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, alignment: .center)

            // 封面图
            AsyncImage(url: media.coverURL) { phase in
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
            .frame(width: 56, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 信息区
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if let native = media.nativeTitle,
                   !native.isEmpty, native != title {
                    Text(native)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let score = media.score {
                    Label(String(format: "%.1f", score), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if !media.genreNames.isEmpty {
                    Text(media.genreNames.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    AnimeRowView(
        entry: AiringEntry(
            id: 1,
            airingAt: Int(Date().timeIntervalSince1970),
            episode: 5,
            media: AniListMedia(
                id: 21,
                title: AniListTitle(romaji: "Frieren", native: "葬送のフリーレン", english: nil),
                description: "A fantasy anime about an elf mage.",
                coverImage: AniListCoverImage(large: nil, medium: nil),
                bannerImage: nil,
                episodes: 28,
                status: "FINISHED",
                genres: ["Adventure", "Drama"],
                averageScore: 87,
                seasonYear: 2023,
                synonyms: nil,
                isAdult: false,
                studios: AniListStudios(nodes: [AniListStudio(name: "Madhouse")]),
                nextAiringEpisode: nil,
                externalLinks: nil
            )
        ),
        chineseTitle: "葬送的芙莉莲"
    )
    .padding()
}
