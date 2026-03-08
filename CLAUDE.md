# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VoiceInputApp is a macOS menu bar application for voice-to-text input using Chinese speech recognition. It captures voice input and types the recognized text into the active application, with support for keyword-triggered keyboard actions.

## Build Commands

```bash
# Build with Swift Package Manager
swift build

# Build release version
swift build -c release

# Open in Xcode for development
open VoiceInputApp.xcodeproj
```

## Architecture

### MVVM Pattern
- **Views/**: SwiftUI views (MainView, SettingsView, FloatingTextWindow)
- **ViewModels/**: ObservableObject classes bridging views and services
- **Models/**: Data structures (AppSettings, KeywordAction, VoiceRecognitionResult)

### Core Services Layer
Services communicate via delegate protocols and are owned by MainViewModel:

1. **SpeechRecognitionService** - Uses Apple's SFSpeechRecognizer (zh-CN locale) for real-time speech-to-text. Manages AVAudioEngine for audio capture.

2. **HotkeyService** - Global keyboard event monitoring via NSEvent.addGlobalMonitorForEvents. Detects FN key via modifier flags (.function/.numericPad). Supports two modes:
   - Single key (hold-to-talk): Release ends recording
   - Combo keys (continuous): Say "结束" to end

3. **KeyboardService** - Simulates keyboard input using CGEvent for typing text and pressing special keys.

4. **ClipboardService** - NSPasteboard wrapper for copy operations.

5. **KeywordProcessor** - Extracts voice commands from recognized text (e.g., "结束" → Enter key, "上移" → Arrow Up).

### App Flow
1. AppDelegate creates status bar item and MainViewModel
2. HotkeyService monitors global keyboard events
3. On trigger: FloatingTextWindow appears, SpeechRecognitionService starts
4. Recognized text updates in real-time via delegate callbacks
5. On completion: KeywordProcessor extracts commands, KeyboardService types text

### Settings Persistence
AppSettings uses UserDefaults with Combine publishers for reactive binding. KeywordAction array is JSON-encoded for storage.

## Required Permissions

The app requires three system permissions:
- **Microphone** (AVCaptureDevice authorization)
- **Speech Recognition** (SFSpeechRecognizer authorization)
- **Accessibility** (AXIsProcessTrusted for keyboard simulation)

AppDelegate handles all permission requests on launch with Chinese localization.

## Key Files

- `VoiceInputApp/App/AppDelegate.swift` - App lifecycle, status bar, permission handling
- `VoiceInputApp/ViewModels/MainViewModel.swift` - Central coordinator for all services
- `VoiceInputApp/Services/HotkeyService.swift` - Global hotkey detection with FN key support
- `VoiceInputApp/Services/SpeechRecognitionService.swift` - Core speech recognition logic
- `VoiceInputApp/Views/FloatingTextWindow.swift` - Floating overlay for real-time feedback

## Platform Requirements

- macOS 13.0+
- Swift 5.9
- Chinese (zh-CN) speech recognition locale