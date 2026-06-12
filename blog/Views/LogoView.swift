//
//  LogoView.swift
//  blog
//
//  Renders the Kernich logo (remote SVG) inside a transparent WKWebView so it
//  can sit as the principal navigation-bar title. SVGs aren't supported by
//  AsyncImage / UIImage, so we download the SVG markup once via LogoLoader
//  and inline it into the page. Colors are forced via CSS so the logo adapts
//  to light & dark mode.
//

import SwiftUI
@preconcurrency import WebKit

struct LogoView: View {
    var height: CGFloat = 28
    var width: CGFloat = 140

    @StateObject private var loader = LogoLoader.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let svg = loader.svg {
                SVGInlineWebView(svg: svg, tint: tintHex)
            } else {
                Text("Blog")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: width, height: height)
        .accessibilityLabel("Kernich")
        .onAppear { loader.loadIfNeeded() }
    }

    private var tintHex: String {
        colorScheme == .dark ? "#FFFFFF" : "#111111"
    }
}

// MARK: - Web view wrapper

private struct SVGInlineWebView: UIViewRepresentable {
    let svg: String
    let tint: String

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
            color: \(tint);
          }
          .wrap svg {
            max-height: 100%;
            max-width: 100%;
            height: 100%;
            width: auto;
            display: block;
          }
          /* Force every fill/stroke in the SVG to the tint color so the
             logo adapts to dark / light appearance. */
          .wrap svg, .wrap svg * {
            fill: \(tint) !important;
            stroke: \(tint) !important;
          }
          .wrap svg [fill="none"], .wrap svg [fill='none'] {
            fill: none !important;
          }
          .wrap svg [stroke="none"], .wrap svg [stroke='none'] {
            stroke: none !important;
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
