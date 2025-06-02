# 🍅 Pomo - Minimalist Pomodoro Timer

A clean, modern iOS Pomodoro timer app built with Swift and SwiftUI. Boost your productivity with focused work sessions and strategic breaks.

## 📱 Screenshots

<p align="center">
  <img src="screenshots/timer-interface.jng" width="180" alt="Clean Timer Interface">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="screenshots/notification-feature.jng" width="180" alt="Smart Notifications">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="screenshots/customization.jng" width="180" alt="Customizable Settings">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="screenshots/statistics-tracking.jng" width="180" alt="Progress Tracking">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="screenshots/dark-light-mode.jng" width="180" alt="Light & Dark Mode">
</p>

## ✨ Features

### Core Functionality
- **🕐 Customizable Timer**: Work sessions (10-60 min), short breaks (3-15 min), and long breaks (10-30 min)
- **🔄 Automatic Session Flow**: Seamlessly transitions between work and break periods
- **⏸️ Pause & Resume**: Full control over your sessions
- **⏭️ Skip Sessions**: Skip breaks when you're in the zone
- **🔄 Reset Timer**: Start fresh anytime

### Smart Features
- **📱 Background Support**: Timer continues running when app is backgrounded
- **🔔 Push Notifications**: Get notified when sessions complete (even when app is closed)
- **🔊 Sound Alerts**: Optional audio notifications for session completion
- **💾 Persistent State**: App remembers your progress if closed unexpectedly

### Analytics & Tracking
- **📊 Daily Statistics**: Track today's completed Pomodoros and total focus time
- **📈 Weekly Charts**: Visual representation of your productivity over the week
- **🔥 Streak Counter**: Maintain your daily productivity streaks
- **📝 Session History**: All sessions are automatically saved with SwiftData

### Customization
- **⚙️ Flexible Settings**: Adjust all timer durations to fit your workflow
- **🎯 Configurable Long Breaks**: Set how many work sessions trigger a long break (2-6 sessions)
- **🔕 Notification Control**: Toggle notifications and sounds independently
- **🌙 Adaptive Design**: Supports both light and dark mode

## 🏗️ Technical Architecture

### Built With
- **Swift 5.0** - Modern, safe programming language
- **SwiftUI** - Declarative UI framework for iOS
- **SwiftData** - Core Data successor for data persistence
- **Combine** - Reactive programming framework
- **UserNotifications** - Background notifications
- **AVFoundation** - Audio playback
- **Charts** - Native chart visualization

### Architecture Pattern
- **MVVM (Model-View-ViewModel)** - Clean separation of concerns
- **Reactive Programming** - Uses Combine for state management
- **Service Layer** - Dedicated services for data, notifications, and audio

### Key Components
```
Pomo/
├── Core/
│   ├── Models/           # Data models (TimerSession, TimerType)
│   ├── ViewModels/       # Business logic (TimerViewModel, etc.)
│   ├── Services/         # App services (DataService, NotificationService)
│   └── Features/         # Feature-specific views and components
├── Shared/
│   ├── Extensions/       # SwiftUI view extensions
│   └── Utils/           # Constants and utilities
└── Resources/           # Assets, localizations, and configurations
```

## 🚀 Getting Started

### Requirements
- **iOS 17.0+**
- **Xcode 16.0+**
- **Swift 5.0+**

### Installation
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/pomo.git
   ```

2. Open the project in Xcode
   ```bash
   cd pomo
   open Pomo.xcodeproj
   ```

3. Build and run on your device or simulator
   ```
   ⌘ + R
   ```

### Configuration
The app works out of the box with sensible defaults:
- **Work sessions**: 25 minutes
- **Short breaks**: 5 minutes  
- **Long breaks**: 15 minutes
- **Sessions until long break**: 4

All settings can be customized in the Settings tab.

## 🎯 Usage

### Basic Workflow
1. **Start a Session**: Tap the play button to begin a work session
2. **Stay Focused**: The circular progress indicator shows remaining time
3. **Take Breaks**: App automatically suggests breaks after work sessions
4. **Track Progress**: View your daily stats and weekly trends
5. **Customize**: Adjust timers and notifications to fit your needs

### Pro Tips
- **Enable notifications** to stay informed even when the app is backgrounded
- **Use the skip feature** sparingly - breaks are important for sustained productivity
- **Check your streak** regularly to maintain consistency
- **Experiment with timer durations** to find what works best for you

## 🌍 Localization

Currently supports:
- **Spanish** (Primary)
- **English**

Easy to extend for additional languages using Xcode's String Catalogs.

## 📝 License

This project is available under the MIT License. See the LICENSE file for more info.

## 🤝 Contributing

This is a personal MVP project, but feedback and suggestions are welcome! Feel free to:
- Report bugs via Issues
- Suggest features 
- Submit pull requests

## 📬 Contact

Created by [Christian Arzaluz](mailto:your.email@example.com)

---

**Ready to boost your productivity? Download Pomo and start your first Pomodoro session today! 🍅**
