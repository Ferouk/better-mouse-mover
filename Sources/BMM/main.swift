import AppKit
import ApplicationServices
import CoreGraphics
import IOKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let mover = MouseMover()
    private var trayIconMenuItems: [NSMenuItem] = []
    private var timer: Timer?
    private var isRunning = false

    private let tickSeconds: TimeInterval = 5
    private let idleThresholdSeconds: TimeInterval = 60

    private lazy var startStopItem = NSMenuItem(
        title: "Start",
        action: #selector(toggleRunning),
        keyEquivalent: ""
    )

    private lazy var statusMenuItem = NSMenuItem(
        title: "Idle: --",
        action: nil,
        keyEquivalent: ""
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.imageScaling = .scaleProportionallyDown
            button.title = ""
            button.toolTip = "Better Mouse Mover"
        }
        updateStatusIcon()

        startStopItem.target = self
        let menu = NSMenu()
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(startStopItem)
        menu.addItem(makeTrayIconMenuItem())
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "About BMM",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu

        start()
    }

    @objc private func toggleRunning() {
        isRunning ? stop() : start()
    }

    private func start() {
        guard Accessibility.isTrusted(prompt: true) else {
            stop()
            if showAccessibilityAlert() == .openSettingsAndQuit {
                Accessibility.openSettings()
                NSApp.terminate(nil)
            }
            return
        }

        isRunning = true
        startStopItem.title = "Stop"
        updateStatusIcon()
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: tickSeconds,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        tick()
    }

    private func stop() {
        isRunning = false
        startStopItem.title = "Start"
        updateStatusIcon()
        timer?.invalidate()
        timer = nil
        statusMenuItem.title = "Stopped"
    }

    private func tick() {
        let idleSeconds = SystemIdleMonitor.currentIdleSeconds()
        statusMenuItem.title = "Idle: \(Int(idleSeconds))s"

        guard idleSeconds >= idleThresholdSeconds else {
            return
        }

        do {
            try mover.nudge()
            statusMenuItem.title = "Moved after \(Int(idleSeconds))s idle"
        } catch {
            stop()
            showMoveFailedAlert(error)
        }
    }

    private func updateStatusIcon() {
        statusItem.button?.image = StatusBarIcon.load(
            named: selectedTrayIconName(),
            enabled: isRunning
        )
        updateTrayIconMenuState()
    }

    private func makeTrayIconMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Tray Icon", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Tray Icon")

        trayIconMenuItems = StatusBarIcon.availableIcons.map { icon in
            let menuItem = NSMenuItem(
                title: icon.title,
                action: #selector(selectTrayIcon(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = icon.resourceName
            submenu.addItem(menuItem)
            return menuItem
        }

        item.submenu = submenu
        updateTrayIconMenuState()
        return item
    }

    private func updateTrayIconMenuState() {
        let selected = selectedTrayIconName()
        for item in trayIconMenuItems {
            item.state = item.representedObject as? String == selected ? .on : .off
        }
    }

    private func selectedTrayIconName() -> String {
        let saved = UserDefaults.standard.string(forKey: StatusBarIcon.defaultsKey)
        guard StatusBarIcon.availableIcons.contains(where: { $0.resourceName == saved }) else {
            return StatusBarIcon.defaultIconName
        }

        return saved ?? StatusBarIcon.defaultIconName
    }

    @objc private func selectTrayIcon(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else {
            return
        }

        UserDefaults.standard.set(name, forKey: StatusBarIcon.defaultsKey)
        updateStatusIcon()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let alert = NSAlert()
        alert.messageText = "Better Mouse Mover"
        alert.informativeText = "Version \(version) (\(build))\nDeveloped by DevNinja42"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showAccessibilityAlert() -> AccessibilityAlertAction {
        let alert = NSAlert()
        alert.messageText = "Accessibility permission is needed"
        alert.informativeText = "Allow Better Mouse Mover in System Settings > Privacy & Security > Accessibility, then quit and reopen the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings and Quit")
        alert.addButton(withTitle: "Not Now")

        return alert.runModal() == .alertFirstButtonReturn ? .openSettingsAndQuit : .notNow
    }

    private func showMoveFailedAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Mouse pointer cannot be moved"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum AccessibilityAlertAction {
    case openSettingsAndQuit
    case notNow
}

enum StatusBarIcon {
    struct Icon {
        let resourceName: String
        let title: String
    }

    static let defaultsKey = "trayIconName"
    static let defaultIconName = "drink"
    static let availableIcons: [Icon] = [
        Icon(resourceName: "coctail", title: "Coctail"),
        Icon(resourceName: "coffee-bean", title: "Coffee Bean"),
        Icon(resourceName: "cup-of-drink", title: "Cup of Drink"),
        Icon(resourceName: "cursor", title: "Cursor"),
        Icon(resourceName: "drink", title: "Drink"),
        Icon(resourceName: "mouse", title: "Mouse"),
        Icon(resourceName: "palm-tree", title: "Palm Tree"),
        Icon(resourceName: "sun", title: "Sun")
    ]

    static func load(named resourceName: String, enabled: Bool) -> NSImage? {
        let fallback = NSImage(
            systemSymbolName: "cursorarrow.motionlines",
            accessibilityDescription: "Better Mouse Mover"
        )
        fallback?.isTemplate = true

        guard
            let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
            let image = NSImage(contentsOf: url)?.copy() as? NSImage
        else {
            return fallback
        }

        let tintedImage = image.tinted(
            with: enabled ? .white : .systemGray,
            size: NSSize(width: 18, height: 18)
        )
        tintedImage.accessibilityDescription = "Better Mouse Mover"
        return tintedImage
    }
}

private extension NSImage {
    func tinted(with color: NSColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceIn)
        image.unlockFocus()

        image.isTemplate = false
        return image
    }
}

enum Accessibility {
    static func isTrusted(prompt: Bool) -> Bool {
        let options = [
            "AXTrustedCheckOptionPrompt": prompt
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

enum SystemIdleMonitor {
    static func currentIdleSeconds() -> TimeInterval {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem")
        )

        guard service != 0 else {
            return 0
        }
        defer {
            IOObjectRelease(service)
        }

        guard
            let property = IORegistryEntryCreateCFProperty(
                service,
                "HIDIdleTime" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? NSNumber
        else {
            return 0
        }

        return TimeInterval(property.uint64Value) / 1_000_000_000
    }
}

final class MouseMover {
    enum MoveError: LocalizedError {
        case cannotReadLocation
        case cannotCreateEvent

        var errorDescription: String? {
            switch self {
            case .cannotReadLocation:
                return "Better Mouse Mover could not read the current mouse location."
            case .cannotCreateEvent:
                return "Better Mouse Mover could not create a macOS mouse movement event."
            }
        }
    }

    private var direction: CGFloat = 1

    func nudge() throws {
        guard let currentEvent = CGEvent(source: nil) else {
            throw MoveError.cannotReadLocation
        }

        let current = currentEvent.location
        let destination = CGPoint(x: current.x + direction, y: current.y)
        direction *= -1

        guard let move = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: destination,
            mouseButton: .left
        ) else {
            throw MoveError.cannotCreateEvent
        }

        move.post(tap: .cghidEventTap)
    }
}

@main
enum BMMApplication {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
