//
//  SearchView.swift
//  blog
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var service: BlogService
    @EnvironmentObject private var bookmarks: BookmarkStore

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if trimmedQuery.isEmpty {
                    ContentUnavailableView(
                        "Search Articles",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Find articles by title, summary, content, or tags."
                        )
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(results) { post in
                            NavigationLink(value: post) {
                                PostRow(
                                    post: post,
                                    isBookmarked: bookmarks.isBookmarked(post)
                                )
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    LogoView()
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles"
            )
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
        }
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [Post] {
        let lowered = trimmedQuery.lowercased()
        guard !lowered.isEmpty else { return [] }
        return service.posts.filter { post in
            post.title.lowercased().contains(lowered) ||
            post.plainSummary.lowercased().contains(lowered) ||
            post.plainContent.lowercased().contains(lowered) ||
            post.tags.contains { $0.lowercased().contains(lowered) }
        }
    }
}
