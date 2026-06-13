//
//  LogoView.swift
//  blog
//
//  Renders the bundled app logo (`logo.svg`) inside a transparent WKWebView
//  so it can sit as the principal navigation-bar title. SVGs aren't supported
//  by AsyncImage / UIImage, so we read the SVG markup once via LogoLoader and
//  inline it into the page. The SVG's own colors (gradient) are preserved.
//

import SwiftUI
@preconcurrency import WebKit

struct LogoView: View {
    var height: CGFloat = 28
    var width: CGFloat = 140

    @StateObject private var loader = LogoLoader.shared

    var body: some View {
        Group {
            if let svg = loader.svg {
                SVGInlineWebView(svg: svg)
            } else {
                Text("Blog")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: width, height: height)
        .accessibilityLabel("Blog")
        .onAppear { loader.loadIfNeeded() }
    }
}

// MARK: - Web view wrapper

private struct SVGInlineWebView: UIViewRepresentable {
    let svg: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.scrollView.bounces = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html(), baseURL: nil)
    }

    private func html() -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            background: transparent;
            height: 100%;
            width: 100%;
            overflow: hidden;
          }
          body {
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .wrap {
            height: 100%;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .wrap svg {
            max-height: 100%;
            max-width: 100%;
            height: 100%;
            width: auto;
            display: block;
          }
        </style>
        </head>
        <body>
          <div class="wrap">\(svg)</div>
        </body>
        </html>
        """
    }
}
