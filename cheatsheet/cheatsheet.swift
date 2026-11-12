import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!
    var visualEffect: NSVisualEffectView!
    var stack: NSStackView!
    var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        updateLayout()

        // アプリ起動・終了時、または3秒ごとにDockの幅を再計算して動的に追従
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateLayout()
        }
    }

    func setupWindow() {
        guard let screen = NSScreen.main else { return }

        let dockAreaHeight = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY : 93.0
        let bottomMargin: CGFloat = 8
        let height: CGFloat = dockAreaHeight - 12
        let cornerRadius: CGFloat = 22

        window = CheatSheetWindow(
            contentRect: NSRect(x: 14, y: bottomMargin, width: 440, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 440, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.11, alpha: 0.88).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0

        stack = NSStackView(frame: NSRect(x: 18, y: 6, width: 440 - 36, height: height - 12))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動 (Dev/Brow..)"),
                ("⇧+D/B..", "該当WSへ送る"),
                ("H/J/K/L", "フォーカス移動 (Vim)"),
                ("F / M", "Float / Full")
            ]
        )

        let wezView = makeSectionView(
            title: "⌃Q WezTerm",
            titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
            items: [
                ("v / s", "縦/横分割"),
                ("h/j/k/l", "ペイン移動"),
                ("z", "ペイン最大化"),
                ("w / c", "WS選択 / 新規タブ")
            ]
        )

        stack.addArrangedSubview(aeroView)
        stack.addArrangedSubview(wezView)
        visualEffect.addSubview(stack)
        window.contentView = visualEffect
        window.orderFrontRegardless()
    }

    @objc func handleAppChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLayout()
        }
    }

    func calculateAvailableWidth() -> CGFloat {
        guard let screen = NSScreen.main else { return 440 }

        let screenWidth = screen.frame.width
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let tilesize = CGFloat(defaults?.integer(forKey: "tilesize") ?? 67)

        // 1. 固定登録アプリ
        let persistentApps = defaults?.array(forKey: "persistent-apps") as? [[String: Any]] ?? []
        var persistentBundles = Set<String>()
        for app in persistentApps {
            if let tile = app["tile-data"] as? [String: Any], let bundle = tile["bundle-identifier"] as? String {
                persistentBundles.insert(bundle.lowercased())
            }
        }

        // 2. 登録外で起動中の通常アプリ（Dockにアイコンが表示されるもの）
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        var nonPersistentRunningCount = 0
        for app in runningApps {
            let bundle = (app.bundleIdentifier ?? "").lowercased()
            if bundle != "com.apple.finder" && !persistentBundles.contains(bundle) {
                nonPersistentRunningCount += 1
            }
        }

        // 3. フォルダ(persistent-others) + ゴミ箱(1)
        let persistentOthers = defaults?.array(forKey: "persistent-others") ?? []
        let othersCount = persistentOthers.count + 1

        let totalItemCount = CGFloat(persistentApps.count + nonPersistentRunningCount + othersCount)

        // Dock全体の横幅を推定:
        // (アイテム数 * タイルサイズ) + (アイテム間の隙間) + 仕切り線(約18pt) + 左右外枠パディング(約28pt)
        let itemSpacing: CGFloat = 10.0
        let separatorWidth: CGFloat = 18.0
        let dockPadding: CGFloat = 28.0
        let estimatedDockWidth = (totalItemCount * tilesize) + ((totalItemCount - 1) * itemSpacing) + separatorWidth + dockPadding

        // 画面幅からDock幅を引いて2で割ったものが「Dockの左端のX座標（左側の空きスペース）」
        let dockLeftSpace = (screenWidth - estimatedDockWidth) / 2.0

        // チートシートの左マージン(14pt) + Dockとの間のクリアランス余白(14pt)を確保
        let leftMargin: CGFloat = 14.0
        let gapToDock: CGFloat = 14.0
        let availableWidth = max(dockLeftSpace - leftMargin - gapToDock, 300)

        return availableWidth
    }

    func updateLayout() {
        guard let screen = NSScreen.main else { return }

        let targetWidth = calculateAvailableWidth()
        let dockAreaHeight = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY : 93.0
        let bottomMargin: CGFloat = 8
        let height: CGFloat = dockAreaHeight - 12
        let leftMargin: CGFloat = 14

        let newFrame = NSRect(x: leftMargin, y: bottomMargin, width: targetWidth, height: height)

        if window.frame != newFrame {
            window.setFrame(newFrame, display: true, animate: true)
            visualEffect.frame = NSRect(x: 0, y: 0, width: targetWidth, height: height)
            stack.frame = NSRect(x: 18, y: 6, width: targetWidth - 36, height: height - 12)
        }
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 1

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        header.textColor = titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
            descLabel.textColor = NSColor(white: 0.85, alpha: 1.0)
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
