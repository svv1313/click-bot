//
//  SettingsView.swift
//  ClickerApp
//
//  Settings window UI
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: ClickerSettings
    @EnvironmentObject var clickerService: ClickerService
    @EnvironmentObject var activityMonitor: UserActivityMonitor
    
    @State private var minIntervalText: String = ""
    @State private var maxIntervalText: String = ""
    @State private var pauseDurationText: String = ""
    @State private var bundleIDText: String = ""
    
    var body: some View {
        Form {
            Section("Click Interval") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Randomized interval between clicks (milliseconds)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Minimum:")
                        TextField("", text: $minIntervalText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: minIntervalText) { newValue in
                                if let value = Int(newValue), value > 0 {
                                    settings.minInterval = value
                                    settings.validateIntervals()
                                    updateTextFields()
                                }
                            }
                        
                        Text("Maximum:")
                        TextField("", text: $maxIntervalText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: maxIntervalText) { newValue in
                                if let value = Int(newValue), value > 0 {
                                    settings.maxInterval = value
                                    settings.validateIntervals()
                                    updateTextFields()
                                }
                            }
                    }
                    
                    Text("Interval changes every 10 minutes to avoid patterns")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("User Activity") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pause duration after user activity (seconds)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("", text: $pauseDurationText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: pauseDurationText) { newValue in
                                if let value = Double(newValue), value > 0 {
                                    settings.pauseAfterUserInputSeconds = value
                                    // Update activity monitor if running
                                    if clickerService.isRunning {
                                        activityMonitor.startMonitoring(pauseDuration: value)
                                    }
                                }
                            }
                    }
                    
                    Text("Clicking pauses automatically when mouse, keyboard, or scroll activity is detected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("App Restriction") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Restrict clicking to frontmost app", isOn: Binding(
                        get: { settings.restrictToFrontmostApp },
                        set: { newValue in
                            print("[ClickerApp] Toggle 'Restrict clicking to frontmost app' clicked: \(newValue ? "ON" : "OFF")")
                            settings.restrictToFrontmostApp = newValue
                        }
                    ))
                    
                    if settings.restrictToFrontmostApp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bundle Identifier:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("com.example.app", text: $bundleIDText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: bundleIDText) { newValue in
                                        settings.allowedBundleID = newValue
                                    }
                                
                                Button("Use Current App") {
                                    print("[ClickerApp] Button 'Use Current App' clicked")
                                    if let frontmostApp = NSWorkspace.shared.frontmostApplication,
                                       let bundleID = frontmostApp.bundleIdentifier {
                                        print("[ClickerApp] Setting bundle ID to: \(bundleID)")
                                        bundleIDText = bundleID
                                        settings.allowedBundleID = bundleID
                                    } else {
                                        print("[ClickerApp] Warning: Could not get frontmost app bundle ID")
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if let frontmostApp = NSWorkspace.shared.frontmostApplication,
                               let bundleID = frontmostApp.bundleIdentifier {
                                Text("Current frontmost app: \(bundleID)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.leading, 20)
                    }
                    
                    Text("When enabled, clicks only occur when the specified app is frontmost")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Status") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(clickerService.isRunning ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(clickerService.isRunning ? "Clicker is running" : "Clicker is stopped")
                            .font(.caption)
                    }
                    
                    if clickerService.isRunning {
                        Text("Clicking will pause automatically during user activity")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 500)
        .padding()
        .onAppear {
            updateTextFields()
        }
    }
    
    private func updateTextFields() {
        minIntervalText = String(settings.minInterval)
        maxIntervalText = String(settings.maxInterval)
        pauseDurationText = String(format: "%.1f", settings.pauseAfterUserInputSeconds)
        bundleIDText = settings.allowedBundleID
    }
}
