// PomoWatch/Views/WatchSettingsView.swift

import SwiftUI

struct WatchSettingsView: View {
    @AppStorage(Constants.UserDefaults.workDuration) private var workDuration: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDuration: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDuration: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak

    var body: some View {
        if #available(watchOS 26, *) {
            glassSettingsView
        } else {
            standardSettingsView
        }
    }

    // MARK: - watchOS 26+ Glassmorphism

    @available(watchOS 26, *)
    private var glassSettingsView: some View {
        List {
            Section {
                Stepper(value: $workDuration, in: 10...60) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "Work", comment: "Work duration label"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(workDuration) min")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pomoPrimary, .pomoSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .onChange(of: workDuration) { syncSettingsToPhone() }

                Stepper(value: $shortBreakDuration, in: 3...15) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "Break", comment: "Short break duration label"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(shortBreakDuration) min")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pomoPrimary, .pomoSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .onChange(of: shortBreakDuration) { syncSettingsToPhone() }

                Stepper(value: $longBreakDuration, in: 10...30) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "Long Break", comment: "Long break duration label"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(longBreakDuration) min")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pomoPrimary, .pomoSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .onChange(of: longBreakDuration) { syncSettingsToPhone() }
            } header: {
                Label(String(localized: "Durations", comment: "Settings section header"), systemImage: "clock.fill")
            }

            Section {
                Stepper(value: $sessionsUntilLongBreak, in: 2...6) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "Sessions", comment: "Sessions until long break label"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(sessionsUntilLongBreak)")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pomoPrimary, .pomoSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .onChange(of: sessionsUntilLongBreak) { syncSettingsToPhone() }
            } header: {
                Label(String(localized: "Long Break", comment: "Long break section header"), systemImage: "arrow.uturn.right.circle")
            }
        }
        .navigationTitle(String(localized: "Settings", comment: "Watch settings navigation title"))
    }

    // MARK: - Pre-watchOS 26 Standard Design

    private var standardSettingsView: some View {
        List {
            Section(String(localized: "Durations", comment: "Settings section header")) {
                Stepper(value: $workDuration, in: 10...60) {
                    HStack {
                        Text(String(localized: "Work", comment: "Work duration label"))
                        Spacer()
                        Text("\(workDuration) min")
                            .foregroundColor(.pomoPrimary)
                    }
                }
                .onChange(of: workDuration) { syncSettingsToPhone() }

                Stepper(value: $shortBreakDuration, in: 3...15) {
                    HStack {
                        Text(String(localized: "Break", comment: "Short break duration label"))
                        Spacer()
                        Text("\(shortBreakDuration) min")
                            .foregroundColor(.pomoPrimary)
                    }
                }
                .onChange(of: shortBreakDuration) { syncSettingsToPhone() }

                Stepper(value: $longBreakDuration, in: 10...30) {
                    HStack {
                        Text(String(localized: "Long Break", comment: "Long break duration label"))
                        Spacer()
                        Text("\(longBreakDuration) min")
                            .foregroundColor(.pomoPrimary)
                    }
                }
                .onChange(of: longBreakDuration) { syncSettingsToPhone() }
            }

            Section(String(localized: "Long Break", comment: "Long break section header")) {
                Stepper(value: $sessionsUntilLongBreak, in: 2...6) {
                    HStack {
                        Text(String(localized: "Sessions", comment: "Sessions until long break label"))
                        Spacer()
                        Text("\(sessionsUntilLongBreak)")
                            .foregroundColor(.pomoPrimary)
                    }
                }
                .onChange(of: sessionsUntilLongBreak) { syncSettingsToPhone() }
            }
        }
        .navigationTitle(String(localized: "Settings", comment: "Watch settings navigation title"))
    }

    // MARK: - Sync

    private func syncSettingsToPhone() {
        let settings = SettingsSync(
            workDuration: workDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            sessionsUntilLongBreak: sessionsUntilLongBreak
        )
        WatchConnectivityManager.shared.syncSettings(settings)
    }
}
