//
//  FeedView.swift
//  blog
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var service: BlogService
    @EnvironmentObject private var bookmarks: BookmarkStore

    var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        LogoView()
                    }
                }
                .refreshable { await service.load() }
        }
        .task {
            if service.posts.isEmpty {
                await service.load()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        switch service.state {
        case .idle:
            ProgressView("Loading articles…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loading where service.posts.isEmpty:
            ProgressView("Loading articles…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message) where service.posts.isEmpty:
            ErrorStateView(message: message) {
                Task { await service.load() }
            }

        default:
            postList
        }
    }

    private var postList: some View {
        List {
            ForEach(service.posts) { post in
                NavigationLink(value: post) {
                    PostRow(post: post,
                            isBookmarked: bookmarks.isBookmarked(post))
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        bookmarks.toggle(post)
                    } label: {
                        Label(
                            bookmarks.isBookmarked(post) ? "Remove" : "Bookmark",
                            systemImage: bookmarks.isBookmarked(post)
                                ? "bookmark.slash"
                                : "bookmark"
                        )
                    }
                    .tint(.accentColor)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
    }
}

// MARK: - Row

struct PostRow: View {
    let post: Post
    let isBookmarked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(post.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }

                metadataLine

                Text(post.plainSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if !post.tags.isEmpty {
                    TagStrip(tags: post.tags)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = post.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder(symbol: "photo")
                default:
                    placeholder(symbol: nil)
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            placeholder(symbol: "doc.text")
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @ViewBuilder
    private func placeholder(symbol: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
            if let symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var metadataLine: some View {
        let parts: [String] = {
            var arr: [String] = []
            if let date = post.publishedAt {
                arr.append(date.formatted(date: .abbreviated, time: .omitted))
            }
            if let minutes = post.readingTime {
                arr.append("\(minutes) min read")
            }
            return arr
        }()

        if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tag strip

struct TagStrip: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags.prefix(6), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.15))
                        )
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Error state

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t load articles", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
