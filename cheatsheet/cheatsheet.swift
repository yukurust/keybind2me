import Cocoa
import SwiftUI

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!
    var backgroundView: NSView!
    var dockHosting: NSView?
    var stack: NSStackView!
    var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        updateLayout()

        // アプリ起動・終了時、または1.5秒ごとにDockの形状を完全実測して動的追従
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

    func setupWindow() {
        let initialWidth: CGFloat = 380
        let initialHeight: CGFloat = 80
        let initialBottomMargin: CGFloat = 6
        let cornerRadius: CGFloat = 28

        window = CheatSheetWindow(
            contentRect: NSRect(x: 0, y: initialBottomMargin, width: initialWidth, height: initialHeight),
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

        stack = NSStackView(frame: NSRect(x: 16, y: 4, width: initialWidth - 32, height: initialHeight - 8))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動"),
                ("⇧+D/B..", "該当WSへ送る"),
                ("H/J/K/L", "フォーカス移動"),
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

        if let glass = DockGlass.make() {
            // Dock のガラスは material の塗りだけでは縁が出ない。glassEffect が縁を描く。
            let container = NSView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
            let host = ClearHostingView(rootView: DockGlassPlate(glass: glass, radius: cornerRadius))
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
        } else if let material = DockGlassMaterial.make() {
            let container = NSView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
            let host = ClearHostingView(rootView: DockMaterialPlate(material: material, radius: cornerRadius))
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
            let glassView = NSGlassEffectView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
            glassView.cornerRadius = cornerRadius

            let contentContainer = NSView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
            contentContainer.addSubview(stack)
            glassView.contentView = contentContainer

            backgroundView = glassView
            applySystemGlassSetting(to: glassView)
        } else {
            let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
            visualEffect.material = .hudWindow
            visualEffect.blendingMode = .behindWindow
            visualEffect.state = .active
            visualEffect.wantsLayer = true
            visualEffect.layer?.cornerRadius = cornerRadius
            visualEffect.layer?.cornerCurve = .continuous
            visualEffect.layer?.masksToBounds = true
            visualEffect.addSubview(stack)

            backgroundView = visualEffect
        }

        window.contentView = backgroundView
        window.orderFrontRegardless()
    }

    @objc func handleAppChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLayout()
        }
    }

    struct DockGeometry {
        let x: CGFloat
        let yFromBottom: CGFloat
        let height: CGFloat
    }

    func getExactDockGeometry() -> DockGeometry? {
        guard let screen = NSScreen.main else { return nil }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
        guard let dockApp = apps.first else { return nil }
        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &value) == .success,
           let children = value as? [AXUIElement] {
            for child in children {
                var posVal: AnyObject?, sizeVal: AnyObject?
                if AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posVal) == .success,
                   AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeVal) == .success,
                   let p = posVal, let s = sizeVal {
                    var pos = CGPoint.zero, size = CGSize.zero
                    if AXValueGetValue(p as! AXValue, .cgPoint, &pos),
                       AXValueGetValue(s as! AXValue, .cgSize, &size),
                       pos.x > 0 && size.height > 20 {
                        let yFromBottom = screen.frame.height - (pos.y + size.height)
                        return DockGeometry(x: pos.x, yFromBottom: yFromBottom, height: size.height)
                    }
                }
            }
        }
        return nil
    }

    @available(macOS 26.0, *)
    func applySystemGlassSetting(to glassView: NSGlassEffectView) {
        // システム設定 > 外観 > Liquid Glass の強度 (NSGlassTintAmount: 0.0〜1.0) をキャッシュなしで最新取得
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        let rawVal = CFPreferencesCopyAppValue("NSGlassTintAmount" as CFString, kCFPreferencesAnyApplication)
        let tintAmount: Double
        if let num = rawVal as? NSNumber {
            tintAmount = num.doubleValue
        } else {
            tintAmount = 0.0
        }

        // システム設定 > アクセシビリティ > 透明度を下げる
        let reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency

        // ベースは常に公式の .clear スタイルを維持（自然な透明感・光沢控えめ）
        if glassView.style != .clear {
            glassView.style = .clear
        }

        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let baseColor = isDark ? NSColor(white: 0.12, alpha: 1.0) : NSColor(white: 0.94, alpha: 1.0)

        if reduceTransparency {
            // 透明度を下げるがONのときはしっかり不透明に
            glassView.tintColor = baseColor.withAlphaComponent(0.92)
        } else {
            // OSの Liquid Glass スライダー (0.0〜1.0) に比例して透過度合いを連続的に変化させる
            let clamped = min(max(tintAmount, 0.0), 1.0)
            let alpha = CGFloat(clamped * 0.65)
            glassView.tintColor = alpha > 0.01 ? baseColor.withAlphaComponent(alpha) : nil
        }
    }

    func updateLayout() {
        guard let screen = NSScreen.main else { return }

        if #available(macOS 26.0, *), let glassView = backgroundView as? NSGlassEffectView {
            applySystemGlassSetting(to: glassView)
        }

        // ウィンドウやアプリの作業領域の下端（Dockの上限ライン = visibleFrame.minY）
        // 上部に1pxの隙間をあけるため - 1.0
        let maxAllowedTop = screen.visibleFrame.minY - 1.0

        let targetWidth: CGFloat
        var targetHeight: CGFloat
        var bottomMargin: CGFloat

        if let geo = getExactDockGeometry() {
            targetWidth = max(geo.x, 260)
            targetHeight = geo.height
            // bottomのgapを1px小さくする (geo.yFromBottom - 1.0)
            bottomMargin = max(geo.yFromBottom - 1.0, 0)

            // 上端が maxAllowedTop (visibleFrame.minY - 1px) を超えないよう調整
            let currentTop = bottomMargin + targetHeight
            if currentTop > maxAllowedTop {
                bottomMargin = maxAllowedTop - targetHeight
            }
        } else {
            targetWidth = 380
            targetHeight = max(maxAllowedTop - 5, 60)
            bottomMargin = 5
        }

        let leftMargin: CGFloat = 0
        let newFrame = NSRect(x: leftMargin, y: bottomMargin, width: targetWidth, height: targetHeight)

        if window.frame != newFrame {
            window.setFrame(newFrame, display: true, animate: true)
            backgroundView.frame = NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            let cornerRadius: CGFloat = 28

            if let host = dockHosting {
                host.frame = NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            } else if #available(macOS 26.0, *), let glassView = backgroundView as? NSGlassEffectView {
                glassView.cornerRadius = cornerRadius
                glassView.contentView?.frame = NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            } else {
                backgroundView.layer?.cornerRadius = cornerRadius
                backgroundView.layer?.cornerCurve = .continuous
            }

            stack.frame = NSRect(x: 16, y: 4, width: targetWidth - 32, height: targetHeight - 8)
        }
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 1.2

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

struct DockMaterialPlate: View {
    var material: Material
    var radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(material)
    }
}

struct DockGlassPlate: View {
    var glass: Glass
    var radius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(Color.clear)
            .glassEffect(glass, in: shape)
    }
}

enum DockGlass {
    // macOS 27.0 (26A428) の SwiftUI._Glass.dock。
    // 公開の Glass と同じ 40 バイトで、glassEffect が Dock の縁を描く。
    private static let dockGetterOffset = 0x00A85AFC

    static func make() -> Glass? {
        guard let base = swiftUICoreBase() else { return nil }
        let getter = base.advanced(by: dockGetterOffset)
        guard getter.load(as: UInt32.self) == 0xD2800309,
              getter.advanced(by: 4).load(as: UInt32.self) == 0xF2F00009 else { return nil }

        var storage = (UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0))
        withUnsafeMutablePointer(to: &storage) { pointer in
            dock_call_glass(getter, getter, UnsafeMutableRawPointer(pointer))
        }
        return withUnsafeBytes(of: &storage) {
            $0.baseAddress!.assumingMemoryBound(to: Glass.self).pointee
        }
    }

    private static func swiftUICoreBase() -> UnsafeRawPointer? {
        _ = dlopen("/System/Library/Frameworks/SwiftUICore.framework/SwiftUICore", RTLD_NOW)
        let count = _dyld_image_count()
        for index in 0..<count {
            let name = String(cString: _dyld_get_image_name(index))
            if name.contains("SwiftUICore.framework/Versions/A/SwiftUICore") {
                return UnsafeRawPointer(_dyld_get_image_header(index))
            }
        }
        return nil
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
