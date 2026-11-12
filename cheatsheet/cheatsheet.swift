import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dockと同じ高さ・すりガラス感
        let width: CGFloat = 480
        let height: CGFloat = 80
        let cornerRadius: CGFloat = 20

        // 画面左下（画面左端から16pt、画面下端から14pt）
        let x: CGFloat = 16
        let y: CGFloat = 14

        let windowRect = NSRect(x: x, y: y, width: width, height: height)

        window = CheatSheetWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear

        // Dock(level 20)の直下(level 19)に設定することで、Dockの下に潜り込ませる
        let dockLevel = Int(CGWindowLevelForKey(.dockWindow)) // 20
        window.level = NSWindow.Level(rawValue: dockLevel - 1) // 19

        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Dock風のすりガラス背景
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.10, alpha: 0.88).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.25).cgColor
        visualEffect.layer?.borderWidth = 1.2

        // コンテンツ用の横並びStackView
        let stack = NSStackView(frame: NSRect(x: 16, y: 8, width: width - 32, height: height - 16))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        // 1. AeroSpace セクション
        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動"),
                ("⇧+D/B..", "送る"),
                ("H/J/K/L", "フォーカス"),
                ("F / M", "Float / Full")
            ]
        )

        // 2. WezTerm セクション (Leader: Ctrl+Q)
        let wezView = makeSectionView(
            title: "⌃Q WezTerm",
            titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
            items: [
                ("v / s", "縦/横分割"),
                ("h/j/k/l", "ペイン移動"),
                ("z", "最大化"),
                ("w / c", "WS / タブ")
            ]
        )

        stack.addArrangedSubview(aeroView)
        stack.addArrangedSubview(wezView)

        visualEffect.addSubview(stack)
        window.contentView = visualEffect

        window.alphaValue = 1.0
        window.orderFrontRegardless()
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 2

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        header.textColor = titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            descLabel.textColor = NSColor(white: 0.82, alpha: 1.0)
            descLabel.isBezeled = false
            descLabel.drawsBackground = false

            row.addArrangedSubview(keyLabel)
            row.addArrangedSubview(descLabel)
            container.addArrangedSubview(row)
        }

        return container
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
