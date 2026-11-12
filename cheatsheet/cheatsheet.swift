import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        // Dockが占有している正確な高さを取得 (通常 93pt)
        let dockAreaHeight = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY : 93.0

        let bottomMargin: CGFloat = 8
        let height: CGFloat = dockAreaHeight - 12 // 81pt
        let width: CGFloat = 490
        let cornerRadius: CGFloat = 22

        let x: CGFloat = 14
        let y: CGFloat = bottomMargin

        let windowRect = NSRect(x: x, y: y, width: width, height: height)

        window = CheatSheetWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear

        // 最前面（すべてのウィンドウより前、Dockより前で完全に見切れないようにする）
        window.level = .screenSaver

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
        visualEffect.layer?.backgroundColor = NSColor(white: 0.11, alpha: 0.88).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0

        // カプセル内部で上下の余白（パディング）を6ptにし、テキスト全体の高さを62ptに抑えて確実に収める
        let stack = NSStackView(frame: NSRect(x: 18, y: 6, width: width - 36, height: height - 12))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 18

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
        container.spacing = 1 // 行間を詰めて上部の見切れを解消

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        header.textColor = titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 5

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
            descLabel.textColor = NSColor(white: 0.84, alpha: 1.0)
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
