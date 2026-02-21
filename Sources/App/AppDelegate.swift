import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timerService: TimerService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance check
        let bundleId = Bundle.main.bundleIdentifier ?? "com.myti.app"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        if running.count > 1 {
            NSApp.terminate(nil)
            return
        }

        Logger.shared.info("App starting")

        // Initialize database
        do {
            try DatabaseManager.shared.setup()
            Logger.shared.info("Database initialized")
        } catch {
            Logger.shared.error("Database setup failed", error: error)
        }

        // Create tray
        setupStatusItem()
        Logger.shared.info("Tray created")

        // Start timer
        timerService = TimerService.shared
        timerService.start()
        Logger.shared.info("Timer started")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // Tray app — keep running when all windows close
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("App quitting")
        timerService?.stop()
        DatabaseManager.shared.close()
    }

    // MARK: - Tray

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image: NSImage? = {
                // .app bundle Resources path (used after `make bundle`)
                if let url = Bundle.main.url(forResource: "trayTemplate", withExtension: "png"),
                   let img = NSImage(contentsOf: url) { return img }
                // SPM resource bundle path (debug builds)
                let execURL = Bundle.main.executableURL ?? Bundle.main.bundleURL
                let resourceBundle = execURL.deletingLastPathComponent().appendingPathComponent("myti_myti.bundle")
                if let bundle = Bundle(url: resourceBundle),
                   let url = bundle.url(forResource: "Resources/Assets.xcassets/TrayIcon.imageset/trayTemplate", withExtension: "png"),
                   let img = NSImage(contentsOf: url) { return img }
                // Named image from asset catalog
                if let img = NSImage(named: "trayTemplate") { return img }
                return nil
            }()

            if let image {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else {
                button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "myti")
            }

            #if DEBUG
            button.title = " Dev"
            #endif
        }

        updateMenu()

        #if DEBUG
        statusItem.button?.toolTip = "myti (dev)"
        #else
        statusItem.button?.toolTip = "myti"
        #endif
    }

    func updateMenu() {
        let menu = NSMenu()
        let tracking = SettingsStore.shared.isTrackingActive()

        let toggleItem = NSMenuItem(
            title: tracking ? "Pause Tracking" : "Start Tracking",
            action: #selector(toggleTracking),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let reportsItem = NSMenuItem(title: "Open Reports", action: #selector(openReports), keyEquivalent: "")
        reportsItem.target = self
        menu.addItem(reportsItem)

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        #if DEBUG
        menu.addItem(.separator())

        let logNowItem = NSMenuItem(title: "Log Now", action: #selector(logNow), keyEquivalent: "")
        logNowItem.target = self
        menu.addItem(logNowItem)

        let resetPromptItem = NSMenuItem(title: "Reset Next Prompt", action: #selector(resetNextPrompt), keyEquivalent: "")
        resetPromptItem.target = self
        menu.addItem(resetPromptItem)
        #endif

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleTracking() {
        let newState = TimerService.shared.toggleTracking()
        updateMenu()
        _ = newState
    }

    @objc private func openReports() {
        WindowManager.shared.showReports()
    }

    @objc private func openSettings() {
        WindowManager.shared.showSettings()
    }

    @objc private func resetNextPrompt() {
        SettingsStore.shared.setNextPromptAt(ISO8601DateFormatter().string(from: Date()))
        TimerService.shared.restart()
        Logger.shared.info("Next prompt reset to now")
    }

    @objc private func logNow() {
        let promptedAt = ISO8601DateFormatter().string(from: Date())
        WindowManager.shared.showPopup(promptedAt: promptedAt)
    }
}
