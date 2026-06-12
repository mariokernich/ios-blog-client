//
//  Post.swift
//  blog
//

import Foundation

/// Represents a single blog post coming from the Hugo JSON output
/// (https://blog.kernich.de/index.json).
struct Post: Identifiable, Hashable, Codable {
    let title: String
    let permalink: URL
    let summary: String
    let content: String

    // MARK: - Optional metadata (populated when Hugo exposes it in JSON)

    /// Publication date. Falls back to the RSS feed when not in JSON.
    var publishedAt: Date?
    /// Featured / cover image URL.
    var image: URL?
    /// Tags / keywords.
    var tags: [String] = []
    /// Estimated reading time in minutes (Hugo `.ReadingTime`).
    var readingTime: Int?
    /// Word count (Hugo `.WordCount`).
    var wordCount: Int?

    /// Stable identifier derived from the permalink.
    var id: String { permalink.absoluteString }

    /// Returns `true` if the post lives under `/posts/`. Pages such as
    /// `Imprint`, `Projects` and `Talks` are filtered out of the feed.
    var isArticle: Bool {
        permalink.path.hasPrefix("/posts/")
    }

    /// Thumbnail URL — uses the explicit `image` field when present, otherwise
    /// falls back to the first `<img src="…">` discovered inside `content`.
    var thumbnailURL: URL? {
        if let image { return image }
        return Self.firstImageURL(in: content, baseURL: permalink)
    }

    /// A plain-text version of `summary` with HTML entities and tags stripped,
    /// suitable for showing in list rows.
    var plainSummary: String {
        Self.stripHTML(summary)
    }

    /// A plain-text version of `content` used for full-text search.
    var plainContent: String {
        Self.stripHTML(content)
    }

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case title, permalink, summary, content
        case date, publishedAt = "published_at"
        case image, cover, thumbnail
        case tags, keywords
        case readingTime = "reading_time"
        case wordCount   = "word_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.title     = try c.decode(String.self, forKey: .title)
        self.permalink = try c.decode(URL.self,    forKey: .permalink)
        self.summary   = (try? c.decode(String.self, forKey: .summary)) ?? ""
        self.content   = (try? c.decode(String.self, forKey: .content)) ?? ""

        // Date (try a couple of common keys/formats)
        let dateString = (try? c.decode(String.self, forKey: .publishedAt))
            ?? (try? c.decode(String.self, forKey: .date))
        self.publishedAt = dateString.flatMap { Self.parseDate($0) }

        // Image — try `image`, `cover`, `thumbnail`
        let imageString = (try? c.decode(String.self, forKey: .image))
            ?? (try? c.decode(String.self, forKey: .cover))
            ?? (try? c.decode(String.self, forKey: .thumbnail))
        self.image = imageString.flatMap { URL(string: $0) }

        // Tags
        if let tags = try? c.decode([String].self, forKey: .tags) {
            self.tags = tags
        } else if let keywords = try? c.decode([String].self, forKey: .keywords) {
            self.tags = keywords
        }

        self.readingTime = try? c.decode(Int.self, forKey: .readingTime)
        self.wordCount   = try? c.decode(Int.self, forKey: .wordCount)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(permalink, forKey: .permalink)
        try c.encode(summary, forKey: .summary)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(publishedAt?.iso8601, forKey: .publishedAt)
        try c.encodeIfPresent(image?.absoluteString, forKey: .image)
        if !tags.isEmpty { try c.encode(tags, forKey: .tags) }
        try c.encodeIfPresent(readingTime, forKey: .readingTime)
        try c.encodeIfPresent(wordCount,   forKey: .wordCount)
    }

    // MARK: - Helpers

    private static func parseDate(_ string: String) -> Date? {
        // ISO-8601 with or without fractional seconds, plus plain yyyy-MM-dd.
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFull.date(from: string) { return d }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: string) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                       "yyyy-MM-dd HH:mm:ss",
                       "yyyy-MM-dd"] {
            df.dateFormat = format
            if let d = df.date(from: string) { return d }
        }
        return nil
    }

    private static func firstImageURL(in html: String, baseURL: URL) -> URL? {
        // Matches: <img ... src="..."> (also handles single quotes).
        let pattern = #"<img[^>]+src=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html,
                                           range: NSRange(html.startIndex...,
                                                          in: html)),
              match.numberOfRanges >= 2,
              let range = Range(match.range(at: 1), in: html)
        else { return nil }

        let src = String(html[range])
        if let url = URL(string: src), url.scheme != nil { return url }
        // Resolve relative URLs against the post's permalink.
        return URL(string: src, relativeTo: baseURL)?.absoluteURL
    }

    private static func stripHTML(_ string: String) -> String {
        let withoutTags = string.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"),
            ("&rsquo;", "’"), ("&lsquo;", "‘"),
            ("&ldquo;", "“"), ("&rdquo;", "”"),
            ("&hellip;", "…"), ("&nbsp;", " ")
        ]
        var output = withoutTags
        for (entity, replacement) in entities {
            output = output.replacingOccurrences(of: entity, with: replacement)
        }
        output = output.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Date {
    var iso8601: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: self)
    }
}
