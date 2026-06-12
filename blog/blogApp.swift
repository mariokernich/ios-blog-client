//
//  blogApp.swift
//  blog
//
//  Created by Mario on 12.06.26.
//

import SwiftUI

@main
struct blogApp: App {
    @StateObject private var blogService = BlogService()
    @StateObject private var bookmarkStore = BookmarkStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blogService)
                .environmentObject(bookmarkStore)
        }
    }
}
