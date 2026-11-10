// PomoCompactViews.swift
//
// Compact and minimal Dynamic Island. When the island is limited in width (iPhone Duo,
// landscape, several activities) the leading side shows the progress ring and the trailing
// side stays empty, which the system then hides, as Apple recommends.

import SwiftUI
import WidgetKit

struct CompactLeadingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        IslandWidthReader { isLimited in
            if isLimited {
                MinimalView(state: state, isStale: isStale)
            } else {
                SessionIcon(state: state, size: 18)
            }
        }
    }
}

struct CompactTrailingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        IslandWidthReader { isLimited in
            if isLimited {
                EmptyView()
            } else if isStale {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(state.islandTint)
                    .accessibilityLabel(String(localized: "Session complete", comment: "Live Activity: session finished"))
            } else {
                HStack(spacing: 3) {
                    if !state.isRunning {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10, weight: .black))
                    }
                    ActivityCountdownText(state: state, isStale: isStale)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 50)
                }
                .foregroundStyle(state.islandTint)
            }
        }
    }
}

struct MinimalView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        ZStack {
            ActivityProgressRing(state: state, isStale: isStale, color: state.islandTint,
                                 track: state.islandTint.opacity(0.3), lineWidth: 2.5)
            SessionIcon(state: state, size: 11)
        }
    }
}
