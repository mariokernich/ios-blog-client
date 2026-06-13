//
//  PostDetailView.swift
//  blog
//

import SwiftUI
@preconcurrency import WebKit

struct PostDetailView: View {
    let post: Post

    @EnvironmentObject private var bookmarks: BookmarkStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ArticleWebView(html: renderedHTML, colorScheme: colorScheme)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(post.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        bookmarks.toggle(post)
                    } label: {
                        Image(systemName: bookmarks.isBookmarked(post)
                              ? "bookmark.fill"
                              : "bookmark")
                    }
                    .accessibilityLabel(bookmarks.isBookmarked(post)
                                        ? "Remove bookmark"
                                        : "Add bookmark")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: post.permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
    }

    // MARK: - HTML rendering

    private var renderedHTML: String {
        let isDark = colorScheme == .dark

        let bg          = isDark ? "#000000" : "#ffffff"
        let fg          = isDark ? "#f2f2f7" : "#1c1c1e"
        let muted       = isDark ? "#8e8e93" : "#6c6c70"
        let accent      = "#0a84ff"
        let codeBg      = isDark ? "#1c1c1e" : "#f5f5f7"
        let codeFg      = isDark ? "#f2f2f7" : "#1c1c1e"
        let blockquote  = isDark ? "#1c1c1e" : "#f2f2f7"
        let border      = isDark ? "#38383a" : "#e5e5ea"
        let chipBg      = isDark ? "rgba(10,132,255,0.18)" : "rgba(10,132,255,0.12)"

        let hero: String = {
            guard let url = post.thumbnailURL else { return "" }
            return "<img class=\"hero\" src=\"\(url.absoluteString)\" alt=\"\">"
        }()

        let metaParts: [String] = {
            var parts: [String] = []
            if let date = post.publishedAt {
                let df = DateFormatter()
                df.dateStyle = .long
                parts.append(df.string(from: date))
            }
            if let minutes = post.readingTime {
                parts.append("\(minutes) min read")
            } else if let words = post.wordCount {
                parts.append("\(words) words")
            }
            return parts
        }()
        let metaLine = metaParts.isEmpty
            ? ""
            : "<p class=\"meta\">\(metaParts.joined(separator: " · "))</p>"

        let tags: String = {
            guard !post.tags.isEmpty else { return "" }
            let chips = post.tags
                .map { "<span class=\"tag\">\(escape($0))</span>" }
                .joined()
            return "<div class=\"tags\">\(chips)</div>"
        }()

        return """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport"
                  content="width=device-width, initial-scale=1, maximum-scale=5">
            <style>
              :root { color-scheme: \(isDark ? "dark" : "light"); }
              html, body {
                margin: 0;
                padding: 0;
                background: \(bg);
                color: \(fg);
                font: -apple-system-body;
                font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text",
                             "Helvetica Neue", sans-serif;
                line-height: 1.6;
                -webkit-font-smoothing: antialiased;
                -webkit-text-size-adjust: 100%;
              }
              .container { padding: 20px 20px 56px; max-width: 720px; margin: 0 auto; }

              img.hero {
                width: calc(100% + 40px);
                margin: -20px -20px 20px;
                display: block;
                max-height: 260px;
                object-fit: cover;
              }

              h1.title {
                font-size: 30px;
                font-weight: 800;
                line-height: 1.15;
                letter-spacing: -0.02em;
                margin: 0 0 10px;
              }
              .meta {
                color: \(muted);
                font-size: 14px;
                margin: 0 0 14px;
              }
              .tags {
                margin: 0 0 24px;
                display: flex;
                flex-wrap: wrap;
                gap: 6px;
              }
              .tag {
                background: \(chipBg);
                color: \(accent);
                font-size: 12px;
                font-weight: 600;
                padding: 4px 10px;
                border-radius: 999px;
              }

              article h1, article h2, article h3, article h4, article h5 {
                line-height: 1.25;
                font-weight: 700;
                letter-spacing: -0.01em;
              }
              article h2 { font-size: 22px; margin: 2em 0 0.5em; }
              article h3 { font-size: 18px; margin: 1.6em 0 0.4em; }
              article h4 { font-size: 16px; margin: 1.4em 0 0.4em; }

              article p { margin: 0 0 1em; }
              article ul, article ol { padding-left: 1.4em; margin: 0 0 1em; }
              article li { margin: 0.25em 0; }

              a { color: \(accent); text-decoration: none; }
              a:active { opacity: 0.6; }

              img, video {
                max-width: 100%;
                height: auto;
                border-radius: 12px;
                margin: 12px 0;
                display: block;
              }
              figure { margin: 16px 0; }
              figure img { margin: 0; }
              figcaption {
                font-size: 13px;
                color: \(muted);
                text-align: center;
                margin-top: 6px;
              }

              code, pre, kbd, samp {
                font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                font-size: 14px;
              }
              :not(pre) > code {
                background: \(codeBg);
                color: \(codeFg);
                padding: 2px 6px;
                border-radius: 6px;
              }
              pre {
                background: \(codeBg);
                color: \(codeFg);
                padding: 14px;
                border-radius: 12px;
                overflow-x: auto;
                line-height: 1.45;
                margin: 1em 0;
              }
              pre code { background: transparent; padding: 0; }

              /* Hugo chroma syntax-highlighting line numbers / wrappers */
              .highlight { margin: 1em 0; border-radius: 12px; overflow: hidden; }
              .highlight pre { margin: 0; border-radius: 0; }
              .chroma { background: \(codeBg); color: \(codeFg); }
              .chroma .lnt, .chroma .ln {
                color: \(muted);
                margin-right: 0.6em;
                user-select: none;
              }
              .chroma .k, .chroma .kd, .chroma .kn, .chroma .kp,
              .chroma .kr, .chroma .kt { color: #ff7ab2; }
              .chroma .s, .chroma .s1, .chroma .s2, .chroma .sb,
              .chroma .sc, .chroma .sd, .chroma .se, .chroma .sh,
              .chroma .si, .chroma .sx, .chroma .sr, .chroma .ss { color: #ffd479; }
              .chroma .c, .chroma .c1, .chroma .cm, .chroma .cp,
              .chroma .cs { color: \(muted); font-style: italic; }
              .chroma .nb, .chroma .nf, .chroma .nx { color: #6ab0ff; }
              .chroma .mi, .chroma .mf, .chroma .mh, .chroma .mo { color: #d0a8ff; }
              .chroma .o, .chroma .ow { color: #ff8e3c; }
              .chroma .na, .chroma .nt { color: #7ee787; }

              blockquote {
                margin: 16px 0;
                padding: 10px 16px;
                background: \(blockquote);
                border-left: 4px solid \(accent);
                border-radius: 8px;
                color: \(fg);
              }
              blockquote p:last-child { margin-bottom: 0; }

              hr {
                border: 0;
                border-top: 1px solid \(border);
                margin: 28px 0;
              }

              table {
                border-collapse: collapse;
                width: 100%;
                margin: 16px 0;
                font-size: 14px;
              }
              th, td {
                border: 1px solid \(border);
                padding: 8px 10px;
                text-align: left;
                vertical-align: top;
              }
              th { background: \(codeBg); font-weight: 600; }
            </style>
          </head>
          <body>
            <div class="container">
              \(hero)
              <h1 class="title">\(escape(post.title))</h1>
              \(metaLine)
              \(tags)
              <article>\(post.content)</article>
            </div>
          </body>
        </html>
        """
    }

    private func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

// MARK: - WKWebView wrapper

private struct ArticleWebView: UIViewRepresentable {
    let html: String
    let colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != html {
            webView.loadHTMLString(html, baseURL: URL(string: "https://kernich.de"))
            context.coordinator.lastHTML = html
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String = ""

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow the initial in-memory HTML load; open everything else externally.
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
