import AppKit
import WebKit

final class CaptureDelegate: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let outputURL: URL

    init(webView: WKWebView, outputURL: URL) {
        self.webView = webView
        self.outputURL = outputURL
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let configuration = WKSnapshotConfiguration()
            configuration.rect = webView.bounds
            configuration.snapshotWidth = 780

            webView.takeSnapshot(with: configuration) { [outputURL = self.outputURL] image, error in
                guard error == nil,
                      let image,
                      let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    fputs("Capture failed: \(error?.localizedDescription ?? "unknown error")\n", stderr)
                    NSApplication.shared.terminate(nil)
                    return
                }

                do {
                    try png.write(to: outputURL)
                    print(outputURL.path)
                    NSApplication.shared.terminate(nil)
                } catch {
                    fputs("Write failed: \(error.localizedDescription)\n", stderr)
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift capture-prototype.swift <variant> <output.png>\n", stderr)
    exit(2)
}

let variant = CommandLine.arguments[1]
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let application = NSApplication.shared
application.setActivationPolicy(.prohibited)

let frame = NSRect(x: 0, y: 0, width: 390, height: 844)
let webView = WKWebView(frame: frame)
let window = NSWindow(
    contentRect: frame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.contentView = webView

let delegate = CaptureDelegate(webView: webView, outputURL: outputURL)
webView.navigationDelegate = delegate

let url = URL(string: "http://127.0.0.1:4173/presence-disclosure.html?variant=\(variant)&capture=1")!
webView.load(URLRequest(url: url))
application.run()
