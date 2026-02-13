//
//  ClickerApp.swift
//  ClickerApp
//
//  Created based on specification.md
//

import SwiftUI
import AppKit

// AppDelegate to handle early initialization
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app to run as menu bar app (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ClickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = ClickerSettings()
    @StateObject private var clickerService = ClickerService()
    @StateObject private var activityMonitor = UserActivityMonitor()
    
    @State private var isSettingsWindowOpen = false
    
    var body: some Scene {
        MenuBarExtra("Clicker", systemImage: "cursorarrow.click") {
            MenuBarView()
                .environmentObject(settings)
                .environmentObject(clickerService)
                .environmentObject(activityMonitor)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(clickerService)
                .environmentObject(activityMonitor)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var settings: ClickerSettings
    @EnvironmentObject var clickerService: ClickerService
    @EnvironmentObject var activityMonitor: UserActivityMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Toggle switch
            Toggle("Enabled", isOn: Binding(
                get: { clickerService.isRunning },
                set: { newValue in
                    print("[ClickerApp] Toggle 'Enabled' clicked: \(newValue ? "ON" : "OFF")")
                    if newValue {
                        clickerService.start(settings: settings, activityMonitor: activityMonitor)
                    } else {
                        clickerService.stop()
                    }
                }
            ))
            .toggleStyle(.switch)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Settings button
            Button(action: {
                print("[ClickerApp] Button 'Settings' clicked")
                if #available(macOS 13.0, *) {
                    NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                    // Fallback for older macOS versions
                    NSApplication.shared.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }) {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            // Quit button
            Button(action: {
                print("[ClickerApp] Button 'Quit' clicked")
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 200)
        .padding(.vertical, 8)
    }
}
