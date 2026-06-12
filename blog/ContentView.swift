//
//  ContentView.swift
//  blog
//
//  Created by Mario on 12.06.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(BlogService())
        .environmentObject(BookmarkStore())
}
