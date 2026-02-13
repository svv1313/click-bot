Build a native macOS menu bar application in Swift using SwiftUI and AppKit that performs automated left mouse clicks with minimal interference to the system and user activity.

This is a background agent app (LSUIElement = YES), with no Dock icon, only a menu bar icon.

The goal is to create a safe, low-resource, configurable clicker that avoids interfering with normal system usage.

⸻

Core requirements

1. App type and UI
	•	Platform: macOS 13+
	•	Language: Swift
	•	Frameworks: SwiftUI + AppKit + CoreGraphics
	•	App type: Menu bar app (MenuBarExtra)
	•	No Dock icon (LSUIElement = YES)
	•	Menu bar icon with:
	•	Toggle switch: Enabled / Disabled
	•	Settings button
	•	Quit button

Settings open in a native SwiftUI settings window.

⸻

2. Click behavior

The app must:
	•	Perform left mouse clicks using CGEvent
	•	Click at the current mouse cursor position
	•	Never move the mouse cursor
	•	Never send keyboard events
	•	Never change focus or activate apps

Use:

CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, …)
CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, …)
post(tap: .cghidEventTap)

⸻

3. Interval system (randomized, configurable)

The click interval must be randomized.

User can configure:
	•	minimum interval in milliseconds (default: 80)
	•	maximum interval in milliseconds (default: 120)

Each click uses:

random(minInterval…maxInterval)

⸻

4. 10-minute profile randomization

Every 10 minutes, the interval profile must change slightly to avoid detectable patterns.

Implementation example:

Every 10 minutes generate multiplier in range:

0.85 … 1.25

Apply multiplier to minInterval and maxInterval.

Do NOT reset timer every click. Use real time tracking.

⸻

5. Minimal system interference (CRITICAL)

The clicker must pause automatically if the user is active.

Detect user activity via:
	•	mouse movement
	•	mouse clicks
	•	keyboard input
	•	scroll events

Use NSEvent global and local monitors.

If user activity detected, pause clicking for configurable duration:

default: 1.5 seconds

User can configure this value.

Also pause if mouse position changed since last click.

This ensures the clicker never fights user input.

⸻

6. Restrict clicking to specific app (IMPORTANT FEATURE)

User can enable:

restrictToFrontmostApp = true/false

If enabled, clicks only occur when frontmost app bundle identifier matches allowedBundleID.

Example:

com.google.Chrome
com.apple.Safari
com.somegame.client

Get frontmost app via:

NSWorkspace.shared.frontmostApplication?.bundleIdentifier

Settings UI must include:
	•	Toggle: Restrict to frontmost app
	•	Text field: bundle identifier
	•	Button: “Use current frontmost app”

⸻

7. Resource efficiency (CRITICAL)

The click loop must NOT use busy waiting.

Use async/await with:

Task.sleep()

The service must consume near-zero CPU when idle.

Structure:

ClickerService class

with:

start()
stop()
runLoop()

running inside Task.detached

⸻

8. Permissions

App must work with macOS Accessibility permission.

Do NOT use private APIs.

Only use:

CoreGraphics CGEvent
NSEvent monitors
NSWorkspace

⸻

9. Architecture

Create clean structure:

ClickerApp.swift
ClickerService.swift
ClickerSettings.swift
UserActivityMonitor.swift
SettingsView.swift

Use ObservableObject for settings.

Use @Published properties.

⸻

10. Persistence

Persist settings using UserDefaults automatically.

Values to persist:

minInterval
maxInterval
restrictToFrontmostApp
allowedBundleID
pauseAfterUserInputSeconds

⸻

11. Safety guarantees

The clicker must NEVER:
	•	move mouse
	•	steal focus
	•	activate apps
	•	send keyboard events
	•	run busy loops

It must be passive and safe.

⸻

12. Expected output

Generate complete working Swift code for all files.

The code must compile and run in Xcode.

Do not generate pseudocode.

Generate production-ready code.

⸻

If possible, also include:
	•	comments explaining critical parts
	•	proper thread safety
	•	clean architecture
