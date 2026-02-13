//
//  ClickerService.swift
//  ClickerApp
//
//  Core clicking service with async/await, randomization, and app restriction
//

import Foundation
import CoreGraphics
import AppKit

class ClickerService: ObservableObject {
    @Published var isRunning: Bool = false
    
    private var clickTask: Task<Void, Never>?
    private var settings: ClickerSettings?
    private var activityMonitor: UserActivityMonitor?
    
    // 10-minute profile randomization (thread-safe)
    private let profileQueue = DispatchQueue(label: "com.clickerapp.profile")
    private var profileStartTime: Date = Date()
    private var currentMultiplier: Double = 1.0
    
    // Thread-safe state
    private let stateQueue = DispatchQueue(label: "com.clickerapp.state", attributes: .concurrent)
    private var runningFlag: Bool = false
    
    // Start the clicker service
    func start(settings: ClickerSettings, activityMonitor: UserActivityMonitor) {
        print("[ClickerService] Starting clicker service")
        stateQueue.async(flags: .barrier) { [weak self] in
            guard let self = self, !self.runningFlag else { 
                print("[ClickerService] Already running, ignoring start request")
                return 
            }
            
            self.runningFlag = true
            self.settings = settings
            self.activityMonitor = activityMonitor
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
            
            // Reset profile timer
            self.profileQueue.sync {
                self.profileStartTime = Date()
                self.currentMultiplier = Double.random(in: 0.85...1.25)
            }
            
            print("[ClickerService] Settings: minInterval=\(settings.minInterval)ms, maxInterval=\(settings.maxInterval)ms")
            print("[ClickerService] App restriction: \(settings.restrictToFrontmostApp ? "enabled (\(settings.allowedBundleID))" : "disabled")")
            
            // Start activity monitoring
            activityMonitor.startMonitoring(pauseDuration: settings.pauseAfterUserInputSeconds)
            
            // Start click loop in detached task
            self.clickTask = Task.detached { [weak self] in
                await self?.runClickLoop()
            }
        }
    }
    
    // Stop the clicker service
    func stop() {
        print("[ClickerService] Stopping clicker service")
        stateQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.runningFlag = false
            
            DispatchQueue.main.async {
                self.isRunning = false
            }
            
            // Cancel click task
            self.clickTask?.cancel()
            self.clickTask = nil
            
            // Stop activity monitoring
            self.activityMonitor?.stopMonitoring()
        }
    }
    
    // Main click loop using async/await (no busy waiting)
    private func runClickLoop() async {
        print("[ClickerService] Click loop started")
        var loopCount = 0
        
        while !Task.isCancelled {
            loopCount += 1
            
            // Check if we should continue running (thread-safe read)
            let shouldContinue = stateQueue.sync { runningFlag }
            if !shouldContinue {
                print("[ClickerService] Click loop stopped (runningFlag = false)")
                break
            }
            
            // Get current settings (may change during runtime) - thread-safe read
            guard let currentSettings = stateQueue.sync(execute: { settings }),
                  let currentActivityMonitor = stateQueue.sync(execute: { activityMonitor }) else {
                print("[ClickerService] Click loop stopped (settings/monitor nil)")
                break
            }
            
            // Log every 100 iterations to avoid spam
            if loopCount % 100 == 0 {
                print("[ClickerService] Loop iteration \(loopCount), isUserActive: \(currentActivityMonitor.isUserActive)")
            }
            
            // Check if user is active - pause if so
            if currentActivityMonitor.isUserActive {
                if loopCount % 50 == 0 {
                    print("[ClickerService] Paused: user is active")
                }
                // Wait a bit before checking again
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                continue
            }
            
            // Check if mouse position changed - pause if so
            // Note: We check this AFTER user activity to avoid false positives from our own clicks
            if currentActivityMonitor.hasMouseMoved() {
                if loopCount % 50 == 0 {
                    print("[ClickerService] Paused: mouse position changed")
                }
                // Wait before checking again
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                continue
            }
            
            // Check app restriction if enabled
            if currentSettings.restrictToFrontmostApp && !currentSettings.allowedBundleID.isEmpty {
                if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                    if frontmostApp.bundleIdentifier != currentSettings.allowedBundleID {
                        if loopCount % 50 == 0 {
                            print("[ClickerService] Paused: frontmost app (\(frontmostApp.bundleIdentifier ?? "unknown")) != allowed app (\(currentSettings.allowedBundleID))")
                        }
                        // Not the allowed app, wait and check again
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        continue
                    }
                } else {
                    if loopCount % 50 == 0 {
                        print("[ClickerService] Paused: no frontmost app")
                    }
                    // No frontmost app, wait and check again
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    continue
                }
            }
            
            // Perform click at current mouse position
            print("[ClickerService] Performing click #\(loopCount)")
            performClick()
            
            // Update profile multiplier every 10 minutes (thread-safe)
            let (elapsed, multiplier) = profileQueue.sync { () -> (TimeInterval, Double) in
                let elapsed = Date().timeIntervalSince(self.profileStartTime)
                if elapsed >= 600.0 { // 10 minutes
                    print("[ClickerService] Updating profile multiplier (10 minutes elapsed)")
                    self.profileStartTime = Date()
                    self.currentMultiplier = Double.random(in: 0.85...1.25)
                }
                return (elapsed, self.currentMultiplier)
            }
            
            // Calculate randomized interval with profile multiplier
            let baseMinInterval = Double(currentSettings.minInterval)
            let baseMaxInterval = Double(currentSettings.maxInterval)
            
            let adjustedMinInterval = baseMinInterval * multiplier
            let adjustedMaxInterval = baseMaxInterval * multiplier
            
            let randomInterval = Double.random(in: adjustedMinInterval...adjustedMaxInterval)
            // Fix: Convert milliseconds to nanoseconds correctly (1ms = 1,000,000 nanoseconds)
            let intervalNanoseconds = UInt64(randomInterval * 1_000_000)
            
            print("[ClickerService] Next click in \(String(format: "%.2f", randomInterval))ms (multiplier: \(String(format: "%.2f", multiplier)))")
            
            // Sleep for the calculated interval (non-blocking, efficient)
            try? await Task.sleep(nanoseconds: intervalNanoseconds)
        }
        
        print("[ClickerService] Click loop ended")
    }
    
    // Perform a left mouse click at current cursor position
    private func performClick() {
        // Get current mouse location
        let mouseLocation = NSEvent.mouseLocation
        
        // Convert to CGPoint (CoreGraphics uses bottom-left origin, NSEvent uses top-left)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgLocation = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)
        
        // Create mouse down event
        guard let mouseDown = CGEvent(mouseEventSource: nil,
                                     mouseType: .leftMouseDown,
                                     mouseCursorPosition: cgLocation,
                                     mouseButton: .left) else {
            print("[ClickerService] ERROR: Failed to create mouseDown event")
            return
        }
        
        // Create mouse up event
        guard let mouseUp = CGEvent(mouseEventSource: nil,
                                   mouseType: .leftMouseUp,
                                   mouseCursorPosition: cgLocation,
                                   mouseButton: .left) else {
            print("[ClickerService] ERROR: Failed to create mouseUp event")
            return
        }
        
        // Post events to the system (does not move cursor or steal focus)
        mouseDown.post(tap: .cghidEventTap)
        
        // Small delay between down and up (realistic click timing)
        // Note: Using Thread.sleep here as it's a very short blocking delay
        // and we're already in a background task
        Thread.sleep(forTimeInterval: 0.005) // 5ms
        
        mouseUp.post(tap: .cghidEventTap)
        
        // We can't directly detect post() failures (it returns Void). If clicks don't work,
        // ensure the app has Accessibility permissions in System Settings.
        print("[ClickerService] Click performed at (\(String(format: "%.0f", cgLocation.x)), \(String(format: "%.0f", cgLocation.y)))")
    }
    
    deinit {
        stop()
    }
}

