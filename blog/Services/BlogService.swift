//
//  BlogService.swift
//  blog
//

import Foundation
import Combine

/// Loads blog posts from the Hugo JSON feed and enriches them with publication
/// dates parsed from the RSS feed.
@MainActor
final class BlogService: ObservableObject {

    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var posts: [Post] = []
    @Published private(set) var state: LoadingState = .idle

    private let jsonURL = URL(string: "https://kernich.de/index.json")!
    private let rssURL  = URL(string: "https://kernich.de/index.xml")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Reloads the feed from the network.
    func load() async {
        state = .loading
        do {
            async let jsonPosts = fetchPosts()
            async let dates = fetchDates()

            let fetched = try await jsonPosts
            let lookup  = (try? await dates) ?? [:]

            let merged = fetched
                .map { post -> Post in
                    var copy = post
                    if let date = lookup[post.permalink.absoluteString] {
                        copy.publishedAt = date
                    }
                    return copy
                }
                .filter { $0.isArticle }
                .sorted { lhs, rhs in
                    switch (lhs.publishedAt, rhs.publishedAt) {
                    case let (l?, r?): return l > r
                    case (_?, nil):    return true
                    case (nil, _?):    return false
                    case (nil, nil):   return lhs.title < rhs.title
                    }
                }

            self.posts = merged
            self.state = .loaded
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Networking

    private func fetchPosts() async throws -> [Post] {
        let (data, response) = try await session.data(from: jsonURL)
        try Self.validate(response)
        return try JSONDecoder().decode([Post].self, from: data)
    }

    /// Returns a map from permalink → publication date by parsing the RSS feed.
    private func fetchDates() async throws -> [String: Date] {
        let (data, response) = try await session.data(from: rssURL)
        try Self.validate(response)
        let parser = RSSDateParser()
        return parser.parse(data: data)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Lightweight RSS parser

private final class RSSDateParser: NSObject, XMLParserDelegate {

    private var currentElement: String = ""
    private var currentLink: String?
    private var currentDate: String?
    private var inItem = false
    private var result: [String: Date] = [:]

    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return df
    }()

    func parse(data: Data) -> [String: Date] {
        result.removeAll()
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            inItem = true
            currentLink = nil
            currentDate = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch currentElement {
        case "link":    currentLink = (currentLink ?? "") + trimmed
        case "pubDate": currentDate = (currentDate ?? "") + trimmed
        default:        break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if let link = currentLink,
               let dateString = currentDate,
               let date = Self.formatter.date(from: dateString) {
                result[link] = date
            }
            inItem = false
        }
    }
}
