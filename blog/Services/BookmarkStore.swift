//
//  BookmarkStore.swift
//  blog
//

import Foundation
import SwiftUI
import Combine

/// Persists bookmarked post identifiers (permalinks) to `UserDefaults`.
@MainActor
final class BookmarkStore: ObservableObject {

    @Published private(set) var bookmarkedIDs: Set<String> = []

    private let defaultsKey = "bookmarked_post_ids"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.array(forKey: defaultsKey) as? [String] {
            self.bookmarkedIDs = Set(saved)
        }
    }

    func isBookmarked(_ post: Post) -> Bool {
        bookmarkedIDs.contains(post.id)
    }

    func toggle(_ post: Post) {
        if bookmarkedIDs.contains(post.id) {
            bookmarkedIDs.remove(post.id)
        } else {
            bookmarkedIDs.insert(post.id)
        }
        persist()
    }

    private func persist() {
        defaults.set(Array(bookmarkedIDs), forKey: defaultsKey)
    }
}
