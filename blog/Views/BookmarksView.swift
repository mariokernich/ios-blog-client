//
//  BookmarksView.swift
//  blog
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var service: BlogService
    @EnvironmentObject private var bookmarks: BookmarkStore

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkedPosts.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text(
                            "Swipe an article in the feed or tap the bookmark "
                            + "icon while reading to save it here."
                        )
                    )
                } else {
                    List {
                        ForEach(bookmarkedPosts) { post in
                            NavigationLink(value: post) {
                                PostRow(post: post, isBookmarked: true)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    bookmarks.toggle(post)
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash")
                                }
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
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
        }
    }

    private var bookmarkedPosts: [Post] {
        service.posts.filter { bookmarks.isBookmarked($0) }
    }
}
