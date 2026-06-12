//
//  LogoLoader.swift
//  blog
//
//  Downloads the remote Kernich SVG once and caches the markup in memory so it
//  can be inlined into views (avoiding cross-origin issues that arise when a
//  WKWebView with baseURL=nil tries to fetch external resources).
//

import Foundation
import Combine

@MainActor
final class LogoLoader: ObservableObject {

    static let shared = LogoLoader()

    static let url = URL(string: "https://kernich.de/wp-content/uploads/2024/11/Kernich-Logo.svg")!

    @Published private(set) var svg: String?

    private var task: Task<Void, Never>?

    private init() {}

    func loadIfNeeded() {
        guard svg == nil, task == nil else { return }
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: Self.url)
                let text = String(data: data, encoding: .utf8) ?? ""
                self.svg = text
            } catch {
                self.svg = nil
            }
            self.task = nil
        }
    }
}
