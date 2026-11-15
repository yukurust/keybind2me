import Cocoa
import SwiftUI

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct CheatSheetItem {
    let key: String
    let detail: String
}

struct CheatSheetSection {
    let title: String
    let titleColor: NSColor
    let items: [CheatSheetItem]
}

enum CheatSheetEdge {
    case leading
    case trailing
}

struct DockGeometry {
    let x: CGFloat
    let width: CGFloat
    let yFromBottom: CGFloat
    let height: CGFloat
}

enum VimiumSheet {
    private static let palette: [NSColor] = [
        NSColor(red: 0.98, green: 0.78, blue: 0.35, alpha: 1.0),
        NSColor(red: 0.98, green: 0.55, blue: 0.42, alpha: 1.0),
    ]

    static let fallback: [CheatSheetSection] = [
        CheatSheetSection(
            title: "スクロール",
            titleColor: palette[0],
            items: [
                CheatSheetItem(key: "j/k/h/l", detail: "スクロール"),
                CheatSheetItem(key: "gg / G", detail: "先頭 / 末尾"),
                CheatSheetItem(key: "d / u", detail: "半ページ"),
                CheatSheetItem(key: "f / F", detail: "リンクを開く"),
            ]
        ),
        CheatSheetSection(
            title: "タブ",
            titleColor: palette[1],
            items: [
                CheatSheetItem(key: "o / O", detail: "ページを開く"),
                CheatSheetItem(key: "H / L", detail: "戻る / 進む"),
                CheatSheetItem(key: "J / K", detail: "前タブ / 次タブ"),
                CheatSheetItem(key: "x / X", detail: "閉じる / 復元"),
            ]
        ),
    ]

    static func load() -> [CheatSheetSection] {
        guard let text = read(), !parse(text).isEmpty else { return fallback }
        return parse(text)
    }

    static func sourceURL() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates: [String] = [
            ProcessInfo.processInfo.environment["KEYBIND2ME_VIMIUM"] ?? "",
            home.appendingPathComponent(".config/aerospace/vimium-key-mappings").path,
            home.appendingPathComponent("repos/github/keybind2me/vimium/key-mappings").path,
        ]
        return candidates
            .filter { !$0.isEmpty }
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func read() -> String? {
        guard let url = sourceURL() else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func parse(_ text: String) -> [CheatSheetSection] {
        var titles: [String] = []
        var rows: [[CheatSheetItem]] = []
        var current = -1
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#") else { continue }
            let body = line.dropFirst().trimmingCharacters(in: .whitespaces)
            if body.hasPrefix("sheet:") {
                let title = body.dropFirst("sheet:".count).trimmingCharacters(in: .whitespaces)
                titles.append(String(title))
                rows.append([])
                current = titles.count - 1
                continue
            }
            guard current >= 0, let bar = body.firstIndex(of: "|") else { continue }
            let key = body[..<bar].trimmingCharacters(in: .whitespaces)
            let detail = body[body.index(after: bar)...].trimmingCharacters(in: .whitespaces)
            if key.isEmpty || detail.isEmpty { continue }
            rows[current].append(CheatSheetItem(key: String(key), detail: String(detail)))
        }
        return zip(titles, rows).enumerated().compactMap { index, pair in
            let (title, items) = pair
            guard !items.isEmpty else { return nil }
            return CheatSheetSection(
                title: title,
                titleColor: palette[index % palette.count],
                items: items
            )
        }
    }
}

final class CheatSheetPlate {
    let edge: CheatSheetEdge
    private let window: CheatSheetWindow
    private let backgroundView: NSView
    private let stack: NSStackView
    private let dockHosting: NSView?
    private let cornerRadius: CGFloat = 28
    private var signature = ""

    init(edge: CheatSheetEdge, sections: [CheatSheetSection], material: Material?) {
        self.edge = edge
        let initial = NSRect(x: 0, y: 6, width: 380, height: 80)
        window = CheatSheetWindow(
            contentRect: initial,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        stack = NSStackView(frame: NSRect(x: 16, y: 4, width: initial.width - 32, height: initial.height - 8))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        if let material {
            let container = NSView(frame: NSRect(origin: .zero, size: initial.size))
            let host = ClearHostingView(
                rootView: DockGlassPlate(material: material, radius: cornerRadius)
            )
            host.frame = container.bounds
            host.autoresizingMask = [.width, .height]
            host.wantsLayer = true
            host.layer?.backgroundColor = NSColor.clear.cgColor
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor.clear.cgColor
            container.addSubview(host)
            container.addSubview(stack)
            dockHosting = host
            backgroundView = container
        } else if #available(macOS 26.0, *) {
            let glassView = NSGlassEffectView(frame: NSRect(origin: .zero, size: initial.size))
            glassView.cornerRadius = cornerRadius
            let contentContainer = NSView(frame: NSRect(origin: .zero, size: initial.size))
            contentContainer.addSubview(stack)
            glassView.contentView = contentContainer
            dockHosting = nil
            backgroundView = glassView
        } else {
            let visualEffect = NSVisualEffectView(frame: NSRect(origin: .zero, size: initial.size))
            visualEffect.material = .hudWindow
            visualEffect.blendingMode = .behindWindow
            visualEffect.state = .active
            visualEffect.wantsLayer = true
            visualEffect.layer?.cornerRadius = cornerRadius
            visualEffect.layer?.cornerCurve = .continuous
            visualEffect.layer?.masksToBounds = true
            visualEffect.addSubview(stack)
            dockHosting = nil
            backgroundView = visualEffect
        }

        window.contentView = backgroundView
        render(sections)
        window.orderFrontRegardless()
    }

    func render(_ sections: [CheatSheetSection]) {
        let next = sections.map { section in
            section.title + "\n" + section.items.map { "\($0.key)|\($0.detail)" }.joined(separator: "\n")
        }.joined(separator: "\n--\n")
        if next == signature { return }
        signature = next

        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for section in sections {
            stack.addArrangedSubview(Self.makeSectionView(section))
        }
    }

    func update(screen: NSScreen, dock: DockGeometry?) {
        if #available(macOS 26.0, *), let glassView = backgroundView as? NSGlassEffectView {
            Self.applySystemGlassSetting(to: glassView)
        }

        guard let rect = Self.frame(edge: edge, screen: screen, dock: dock) else {
            window.orderOut(nil)
            return
        }
        if !window.isVisible {
            window.orderFrontRegardless()
        }
        guard window.frame != rect else { return }

        window.setFrame(rect, display: true, animate: true)
        backgroundView.frame = NSRect(origin: .zero, size: rect.size)
        if let host = dockHosting {
            host.frame = backgroundView.bounds
        } else if #available(macOS 26.0, *), let glassView = backgroundView as? NSGlassEffectView {
            glassView.cornerRadius = cornerRadius
            glassView.contentView?.frame = backgroundView.bounds
        } else {
            backgroundView.layer?.cornerRadius = cornerRadius
            backgroundView.layer?.cornerCurve = .continuous
        }
        stack.frame = NSRect(x: 16, y: 4, width: rect.width - 32, height: rect.height - 8)
    }

    private static func frame(edge: CheatSheetEdge, screen: NSScreen, dock: DockGeometry?) -> NSRect? {
        let maxAllowedTop = screen.visibleFrame.minY - 1.0
        if let dock {
            var bottom = max(dock.yFromBottom - 1.0, 0)
            let height = dock.height
            if bottom + height > maxAllowedTop {
                bottom = maxAllowedTop - height
            }
            switch edge {
            case .leading:
                let x = screen.frame.minX
                let width = max(dock.x - x, 260)
                return NSRect(x: x, y: bottom, width: width, height: height)
            case .trailing:
                let x = dock.x + dock.width
                let width = screen.frame.maxX - x
                guard width >= 180 else { return nil }
                return NSRect(x: x, y: bottom, width: width, height: height)
            }
        }

        let height = max(maxAllowedTop - 5, 60)
        let width: CGFloat = 380
        let x = edge == .leading ? screen.frame.minX : screen.frame.maxX - width
        return NSRect(x: x, y: 5, width: width, height: height)
    }

    @available(macOS 26.0, *)
    private static func applySystemGlassSetting(to glassView: NSGlassEffectView) {
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        let rawVal = CFPreferencesCopyAppValue("NSGlassTintAmount" as CFString, kCFPreferencesAnyApplication)
        let tintAmount: Double
        if let num = rawVal as? NSNumber {
            tintAmount = num.doubleValue
        } else {
            tintAmount = 0.0
        }

        let reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        if glassView.style != .clear {
            glassView.style = .clear
        }

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let baseColor = isDark ? NSColor(white: 0.12, alpha: 1.0) : NSColor(white: 0.94, alpha: 1.0)
        if reduceTransparency {
            glassView.tintColor = baseColor.withAlphaComponent(0.92)
        } else {
            let clamped = min(max(tintAmount, 0.0), 1.0)
            let alpha = CGFloat(clamped * 0.65)
            glassView.tintColor = alpha > 0.01 ? baseColor.withAlphaComponent(alpha) : nil
        }
    }

    private static func makeSectionView(_ section: CheatSheetSection) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 1.2

        let header = NSTextField(labelWithString: section.title)
        header.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        header.textColor = section.titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for item in section.items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: item.key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: item.detail)
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

class AppDelegate: NSObject, NSApplicationDelegate {
    var plates: [CheatSheetPlate] = []
    var updateTimer: Timer?
    private var vimiumMtime: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let material = DockGlassMaterial.make()
        let leading = CheatSheetPlate(
            edge: .leading,
            sections: [
                CheatSheetSection(
                    title: "⌥ AeroSpace",
                    titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
                    items: [
                        CheatSheetItem(key: "H/J/K/L", detail: "フォーカス移動"),
                        CheatSheetItem(key: "Shift+H/J/K/L", detail: "窓位置入れ替え"),
                        CheatSheetItem(key: "- / ; / Shift+-", detail: "サイズ/等倍"),
                        CheatSheetItem(key: "F / M", detail: "Float / Full"),
                    ]
                ),
                CheatSheetSection(
                    title: "⌃Q WezTerm",
                    titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
                    items: [
                        CheatSheetItem(key: "d / r", detail: "縦/横分割"),
                        CheatSheetItem(key: "h/j/k/l", detail: "ペイン移動"),
                        CheatSheetItem(key: "s → hjkl", detail: "サイズ変更"),
                        CheatSheetItem(key: "z / x", detail: "最大化/閉じる"),
                    ]
                ),
            ],
            material: material
        )
        let trailing = CheatSheetPlate(edge: .trailing, sections: VimiumSheet.load(), material: material)
        plates = [leading, trailing]
        updateLayout()

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
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.updateLayout()
        }
    }

    @objc func handleAppChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLayout()
        }
    }

    func dockGeometry() -> DockGeometry? {
        if let exact = exactDockGeometry() { return exact }
        return estimatedDockGeometry()
    }

    func exactDockGeometry() -> DockGeometry? {
        guard let screen = NSScreen.main else { return nil }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
        guard let dockApp = apps.first else { return nil }
        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &value) == .success,
              let children = value as? [AXUIElement] else { return nil }
        for child in children {
            var posVal: AnyObject?
            var sizeVal: AnyObject?
            guard AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posVal) == .success,
                  AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeVal) == .success,
                  let posVal, let sizeVal else { continue }
            var pos = CGPoint.zero
            var size = CGSize.zero
            guard AXValueGetValue(posVal as! AXValue, .cgPoint, &pos),
                  AXValueGetValue(sizeVal as! AXValue, .cgSize, &size),
                  pos.x > 0, size.height > 20 else { continue }
            let yFromBottom = screen.frame.height - (pos.y + size.height)
            return DockGeometry(x: pos.x, width: size.width, yFromBottom: yFromBottom, height: size.height)
        }
        return nil
    }

    // Dock は中央置き。タイルサイズとアイコン数から幅を推定し、左右の空きが同じになるようにする。
    // アクセシビリティで実測できないときも、システム設定の Dock サイズ変更に追従する。
    func estimatedDockGeometry() -> DockGeometry? {
        guard let screen = NSScreen.main else { return nil }
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let storedTile = defaults?.integer(forKey: "tilesize") ?? 0
        let tilesize = CGFloat(storedTile > 0 ? storedTile : 67)

        let persistentApps = defaults?.array(forKey: "persistent-apps") as? [[String: Any]] ?? []
        var countedBundles = Set<String>()
        for app in persistentApps {
            if let tile = app["tile-data"] as? [String: Any],
               let bundle = tile["bundle-identifier"] as? String {
                countedBundles.insert(bundle.lowercased())
            }
        }
        let finderCount = countedBundles.contains("com.apple.finder") ? 0 : 1

        var nonPersistentRunningCount = 0
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            let bundle = (app.bundleIdentifier ?? "").lowercased()
            if bundle.isEmpty || bundle == "com.apple.finder" || countedBundles.contains(bundle) { continue }
            countedBundles.insert(bundle)
            nonPersistentRunningCount += 1
        }

        let showRecents = (defaults?.object(forKey: "show-recents") as? Bool) ?? true
        var recentCount = 0
        if showRecents, let recentApps = defaults?.array(forKey: "recent-apps") as? [[String: Any]] {
            for app in recentApps {
                let tile = app["tile-data"] as? [String: Any]
                let bundle = (tile?["bundle-identifier"] as? String)?.lowercased() ?? ""
                if !bundle.isEmpty && !countedBundles.contains(bundle) {
                    countedBundles.insert(bundle)
                    recentCount += 1
                }
            }
        }

        let othersCount = (defaults?.array(forKey: "persistent-others")?.count ?? 0) + 1
        let pinnedCount = persistentApps.count + finderCount
        let openCount = nonPersistentRunningCount + recentCount
        var sectionCount = 0
        if pinnedCount > 0 { sectionCount += 1 }
        if openCount > 0 { sectionCount += 1 }
        if othersCount > 0 { sectionCount += 1 }
        let dividerCount = max(sectionCount - 1, 0)

        // 間隔・端・区切りはタイルほど縮まない。tilesize 40 と 70 で端が Dock に合うように合わせてある。
        let totalItemCount = CGFloat(pinnedCount + openCount + othersCount)
        let gap = max(tilesize * 0.1 - 2, 0)
        let cap = max(tilesize / 3 - 28.0 / 3, 0)
        let divider = max(tilesize * (37.0 / 30) - 91.0 / 3, 0)
        let dockWidth = max(totalItemCount - 1, 0) * (tilesize + gap)
            + (tilesize / 2 + cap) * 2
            + CGFloat(dividerCount) * divider
        let left = max((screen.frame.width - dockWidth) / 2, 0)
        let band = max(screen.visibleFrame.minY - screen.frame.minY - 1, 48)
        return DockGeometry(
            x: screen.frame.minX + left,
            width: min(dockWidth, screen.frame.width),
            yFromBottom: 0,
            height: band
        )
    }

    func updateLayout() {
        guard let screen = NSScreen.main else { return }
        reloadVimiumSheet()
        let dock = dockGeometry()
        for plate in plates {
            plate.update(screen: screen, dock: dock)
        }
    }

    private func reloadVimiumSheet() {
        guard let url = VimiumSheet.sourceURL() else { return }
        let mtime = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        if mtime == vimiumMtime { return }
        vimiumMtime = mtime
        plates.first { $0.edge == .trailing }?.render(VimiumSheet.load())
    }
}

struct DockGlassPlate: View {
    var material: Material
    var radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(material)
    }
}

final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
}

enum DockGlassMaterial {
    // macOS 27.0 (26A428) の SwiftUI にある Material._GlassVariant.dock。
    // この getter が DesignLibrary.GlassMaterialProvider.Configuration.dock を組む。
    private static let dockGetterOffset = 0x0137F4E8
    private static let glassFunctionOffset = 0x0137EFC4

    static func make() -> Material? {
        guard let base = swiftUIBase() else { return nil }
        guard let sites = thunkSites(base: base) else { return nil }
        let glass = base.advanced(by: glassFunctionOffset)
        guard glass.load(as: UInt32.self) == 0xD503237F else { return nil }

        let variant = UnsafeMutableRawPointer.allocate(byteCount: 256, alignment: 16)
        defer { variant.deallocate() }
        variant.initializeMemory(as: UInt8.self, repeating: 0, count: 256)
        dock_call_tail(sites.tail, sites.global, sites.global.advanced(by: 8), sites.helper, variant)

        var storage = (UInt64(0), UInt64(0), UInt64(0))
        withUnsafeMutablePointer(to: &storage) { pointer in
            dock_call_glass(glass, variant, UnsafeMutableRawPointer(pointer))
        }
        return withUnsafeBytes(of: &storage) {
            $0.baseAddress!.assumingMemoryBound(to: Material.self).pointee
        }
    }

    private struct ThunkSites {
        let tail: UnsafeRawPointer
        let global: UnsafeRawPointer
        let helper: UnsafeRawPointer
    }

    private static func swiftUIBase() -> UnsafeRawPointer? {
        _ = dlopen("/System/Library/Frameworks/SwiftUI.framework/SwiftUI", RTLD_NOW)
        _ = dlopen("/System/Library/PrivateFrameworks/DesignLibrary.framework/DesignLibrary", RTLD_NOW)
        let count = _dyld_image_count()
        for index in 0..<count {
            let name = String(cString: _dyld_get_image_name(index))
            if name.contains("SwiftUI.framework/Versions/A/SwiftUI") {
                return UnsafeRawPointer(_dyld_get_image_header(index))
            }
        }
        return nil
    }

    private static func thunkSites(base: UnsafeRawPointer) -> ThunkSites? {
        let getter = base.advanced(by: dockGetterOffset)
        let paciza = getter.advanced(by: 24).load(as: UInt32.self)
        let move = getter.advanced(by: 28).load(as: UInt32.self)
        guard paciza == 0xDAC123F0, move == 0xAA1003E2 else { return nil }
        let branch = getter.advanced(by: 32).load(as: UInt32.self)
        guard branch & 0xFC000000 == 0x14000000 else { return nil }
        var imm = Int(branch & 0x03FFFFFF)
        if imm & (1 << 25) != 0 { imm -= 1 << 26 }
        let tail = getter.advanced(by: 32 + imm * 4)
        guard let global = adrpTarget(base: base, instruction: dockGetterOffset),
              let helper = adrpTarget(base: base, instruction: dockGetterOffset + 16) else { return nil }
        return ThunkSites(tail: tail, global: global, helper: helper)
    }

    private static func adrpTarget(base: UnsafeRawPointer, instruction: Int) -> UnsafeRawPointer? {
        let word = base.advanced(by: instruction).load(as: UInt32.self)
        guard word & 0x9F000000 == 0x90000000 else { return nil }
        let pc = UInt(bitPattern: base) + UInt(instruction)
        let immlo = (word >> 29) & 3
        let immhi = (word >> 5) & 0x7FFFF
        var imm = (immhi << 2) | immlo
        if imm & (1 << 20) != 0 { imm = imm &- (1 << 21) }
        let page = (pc & ~0xFFF) &+ UInt(bitPattern: Int(imm) << 12)
        let add = base.advanced(by: instruction + 4).load(as: UInt32.self)
        guard add & 0xFF800000 == 0x91000000 else { return nil }
        let addimm = UInt((add >> 10) & 0xFFF)
        return UnsafeRawPointer(bitPattern: page &+ addimm)
    }
}

@_silgen_name("dock_call_tail")
func dock_call_tail(_ tail: UnsafeRawPointer, _ global: UnsafeRawPointer, _ globalPlus8: UnsafeRawPointer, _ helper: UnsafeRawPointer, _ ret: UnsafeMutableRawPointer)
@_silgen_name("dock_call_glass")
func dock_call_glass(_ glass: UnsafeRawPointer, _ variant: UnsafeRawPointer, _ ret: UnsafeMutableRawPointer)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
