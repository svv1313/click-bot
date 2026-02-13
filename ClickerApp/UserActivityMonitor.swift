//
//  UserActivityMonitor.swift
//  ClickerApp
//
//  Monitors user activity (mouse, keyboard, scroll) to pause clicking
//

import AppKit
import Foundation
import Combine

class UserActivityMonitor: ObservableObject {
    @Published var isUserActive: Bool = false
    
    private var globalMouseMonitor: Any?
    private var globalKeyboardMonitor: Any?
    private var localMouseMonitor: Any?
    private var localKeyboardMonitor: Any?
    
    private var lastMousePosition: NSPoint = .zero
    private var activityTimer: Timer?
    
    var pauseDuration: TimeInterval = 1.5
    
    init() {
        // Initialize with current mouse position
        lastMousePosition = NSEvent.mouseLocation
    }
    
    // Start monitoring user activity
    func startMonitoring(pauseDuration: TimeInterval) {
        print("[UserActivityMonitor] Starting monitoring with pause duration: \(pauseDuration)s")
        // Stop existing monitoring first to avoid duplicates
        stopMonitoring()
        
        self.pauseDuration = pauseDuration
        
        // Global monitors for system-wide events
        // Note: We monitor mouse movement, but clicks from CGEvent.post() shouldn't trigger these
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]) { [weak self] event in
            // Only log mouse movement, not clicks (to avoid spam from user clicks)
            if event.type == .mouseMoved {
                self?.handleUserActivity()
            } else {
                // For clicks, only handle if mouse position changed
                self?.handleUserActivity()
            }
        }
        
        globalKeyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleUserActivity()
        }
        
        // Local monitors for events within the app
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]) { [weak self] event in
            if event.type == .mouseMoved {
                self?.handleUserActivity()
            } else {
                self?.handleUserActivity()
            }
            return event
        }
        
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleUserActivity()
            return event
        }
        
        if globalMouseMonitor == nil {
            print("[UserActivityMonitor] WARNING: Failed to create global mouse monitor (check Accessibility permissions)")
        }
    }
    
    // Stop monitoring
    func stopMonitoring() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        
        if let monitor = globalKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyboardMonitor = nil
        }
        
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
        
        if let monitor = localKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyboardMonitor = nil
        }
        
        activityTimer?.invalidate()
        activityTimer = nil
        isUserActive = false
    }
    
    // Handle user activity detection
    private func handleUserActivity() {
        let currentMousePosition = NSEvent.mouseLocation
        
        // Only mark as active if mouse position actually changed
        // This prevents the clicker's own clicks from triggering activity detection
        if currentMousePosition != lastMousePosition {
            lastMousePosition = currentMousePosition
            markUserActive()
        }
        // Note: We don't mark as active for clicks/keyboard events at the same position
        // to avoid false positives from the clicker's own actions
    }
    
    // Mark user as active and set timer to clear
    private func markUserActive() {
        // Update on main thread since isUserActive is @Published
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Only log if state is changing
            if !self.isUserActive {
                print("[UserActivityMonitor] User activity detected, pausing for \(self.pauseDuration)s")
            }
            
            self.isUserActive = true
            
            // Cancel existing timer
            self.activityTimer?.invalidate()
            
            // Set timer to clear active state after pause duration
            // Timer scheduled on main run loop for UI updates
            self.activityTimer = Timer.scheduledTimer(withTimeInterval: self.pauseDuration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    print("[UserActivityMonitor] User activity pause ended, resuming clicks")
                    self?.isUserActive = false
                }
            }
        }
    }
    
    // Check if mouse position has changed since last check
    func hasMouseMoved() -> Bool {
        let currentPosition = NSEvent.mouseLocation
        if currentPosition != lastMousePosition {
            lastMousePosition = currentPosition
            return true
        }
        return false
    }
    
    deinit {
        stopMonitoring()
    }
}
