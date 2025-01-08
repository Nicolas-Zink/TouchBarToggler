import SwiftUI
import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var lastCommandPress: Date?
    private var eventMonitor: Any?
    private let doublePressDuration = 0.3
    private var isEnabled = true
    
    override init() {
        super.init()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Touch Bar Controller")
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Touch Bar", action: #selector(toggleTouchBar), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        // Start monitoring keyboard events
        startEventMonitor()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkSIPStatus()
    }
    
    private func checkSIPStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/csrutil")
        task.arguments = ["status"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if output.contains("enabled") {
                let alert = NSAlert()
                alert.messageText = "System Integrity Protection Enabled"
                alert.informativeText = "This app requires System Integrity Protection to be disabled to function properly. Please disable SIP in Recovery Mode:\n\n1. Restart your Mac\n2. Hold Power button during startup\n3. Open Terminal from Utilities menu\n4. Run: csrutil disable\n5. Restart your Mac"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } catch {
            print("Error checking SIP status: \(error)")
        }
    }
    
    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let commandKeyMask: NSEvent.ModifierFlags = .command
        let isCommandKeyPress = event.modifierFlags.contains(commandKeyMask)
        
        if isCommandKeyPress {
            let now = Date()
            if let lastPress = lastCommandPress {
                let timeSinceLastPress = now.timeIntervalSince(lastPress)
                if timeSinceLastPress < doublePressDuration {
                    toggleTouchBar()
                    lastCommandPress = nil
                    return
                }
            }
            lastCommandPress = now
        }
    }
    
    @objc private func toggleTouchBar() {
        isEnabled.toggle()
        
        do {
            if isEnabled {
                try enableTouchBar()
            } else {
                try disableTouchBar()
            }
            
            // Update menu bar icon
            if let button = statusItem.button {
                button.image = NSImage(systemSymbolName: isEnabled ? "command" : "command.circle.fill",
                                    accessibilityDescription: "Touch Bar Controller")
            }
        } catch {
            print("Error toggling Touch Bar: \(error)")
            
            let alert = NSAlert()
            alert.messageText = "Error Toggling Touch Bar"
            alert.informativeText = "Make sure System Integrity Protection is disabled and try again."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func enableTouchBar() throws {
        let presentationModeProperties = "<dict><key>app</key><string>fullControlStrip</string><key>appWithControlStrip</key><string>fullControlStrip</string><key>fullControlStrip</key><string>app</string></dict>"
        
        try runCommand("/usr/bin/defaults", args: ["delete", "com.apple.touchbar.agent", "PresentationModeGlobal"])
        try runCommand("/usr/bin/defaults", args: ["write", "com.apple.touchbar.agent", "PresentationModeFnModes", presentationModeProperties])
        
        try runCommand("/bin/launchctl", args: ["load", "/System/Library/LaunchAgents/com.apple.controlstrip.plist"])
        try runCommand("/bin/launchctl", args: ["load", "/System/Library/LaunchAgents/com.apple.touchbar.agent.plist"])
        try runCommand("/bin/launchctl", args: ["load", "/System/Library/LaunchDaemons/com.apple.touchbar.user-device.plist"])
        
        try runCommand("/usr/bin/pkill", args: ["ControlStrip"])
        try runCommand("/usr/bin/pkill", args: ["Touch Bar agent"])
        try runCommand("/usr/bin/pkill", args: ["Dock"])
    }
    
    private func disableTouchBar() throws {
        try runCommand("/usr/bin/defaults", args: ["write", "com.apple.touchbar.agent", "PresentationModeGlobal", "-string", "fullControlStrip"])
        
        try runCommand("/bin/launchctl", args: ["unload", "/System/Library/LaunchAgents/com.apple.controlstrip.plist"])
        try runCommand("/bin/launchctl", args: ["unload", "/System/Library/LaunchAgents/com.apple.touchbar.agent.plist"])
        try runCommand("/bin/launchctl", args: ["unload", "/System/Library/LaunchDaemons/com.apple.touchbar.user-device.plist"])
        
        try runCommand("/usr/bin/pkill", args: ["ControlStrip"])
        try runCommand("/usr/bin/pkill", args: ["Touch Bar agent"])
        try runCommand("/usr/bin/pkill", args: ["Dock"])
    }
    
    private func runCommand(_ command: String, args: [String]) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = args
        try task.run()
        task.waitUntilExit()
    }
}

@main
struct TouchBarTogglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
