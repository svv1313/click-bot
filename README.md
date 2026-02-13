# Click Bot - macOS Menu Bar Clicker

A native macOS menu bar application that performs automated left mouse clicks with minimal system interference.

## Features

- **Menu Bar App**: Runs in the menu bar only, no Dock icon
- **Safe Clicking**: Clicks at current cursor position without moving the mouse or stealing focus
- **Randomized Intervals**: Configurable min/max interval with randomization
- **Profile Randomization**: Interval profile changes every 10 minutes to avoid patterns
- **User Activity Detection**: Automatically pauses when user activity is detected
- **App Restriction**: Optionally restrict clicking to specific applications
- **Resource Efficient**: Uses async/await, no busy loops, near-zero CPU when idle
- **Persistent Settings**: All settings saved automatically using UserDefaults

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Building

1. Open the project in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘R)

## Permissions

The app requires **Accessibility** permission to perform automated clicks:
1. System Settings → Privacy & Security → Accessibility
2. Enable the app in the list

## Usage

1. Launch the app (it will appear in the menu bar)
2. Click the menu bar icon
3. Toggle "Enabled" to start/stop clicking
4. Open Settings to configure:
   - Click interval (min/max milliseconds)
   - Pause duration after user activity
   - App restriction (optional)

## Architecture

- `ClickerApp.swift` - Main app entry point and menu bar UI
- `ClickerService.swift` - Core clicking logic with async/await
- `ClickerSettings.swift` - Settings model with UserDefaults persistence
- `UserActivityMonitor.swift` - User activity detection via NSEvent monitors
- `SettingsView.swift` - Settings window UI

## Safety Guarantees

The clicker will NEVER:
- Move the mouse cursor
- Steal focus or activate apps
- Send keyboard events
- Run busy loops
- Interfere with normal system usage

It is designed to be passive and safe, automatically pausing during user activity.
