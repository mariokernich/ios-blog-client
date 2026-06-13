//
//  LogoLoader.swift
//  blog
//
//  Loads the bundled `logo.svg` once and caches the markup in memory so it
//  can be inlined into views (SVGs aren't supported natively by UIImage /
//  AsyncImage, so we render them via a transparent WKWebView).
//

import Foundation
import Combine

@MainActor
final class LogoLoader: ObservableObject {

    static let shared = LogoLoader()

    /// Name (without extension) of the bundled SVG asset.
    static let resourceName = "logo-wide"
    static let resourceExtension = "svg"

    @Published private(set) var svg: String?

    private init() {}

    func loadIfNeeded() {
        guard svg == nil else { return }
        guard let url = Bundle.main.url(
            forResource: Self.resourceName,
            withExtension: Self.resourceExtension
        ) else {
            svg = nil
            return
        }
        svg = try? String(contentsOf: url, encoding: .utf8)
    }
}
