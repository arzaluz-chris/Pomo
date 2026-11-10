// PomoCompactViews.swift

import SwiftUI
import WidgetKit

struct CompactLeadingView: View {
    let state: PomoActivityAttributes.ContentState

    var body: some View {
        SessionIcon(state: state, size: 16)
    }
}

struct CompactTrailingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(state.tint)
                .accessibilityLabel(String(localized: "Session complete", comment: "Live Activity: session finished"))
        } else {
            HStack(spacing: 2) {
                if !state.isRunning {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(state.tint)
                }
                ActivityCountdownText(state: state, isStale: isStale)
                    .monospacedDigit()
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 48)
            }
        }
    }
}

struct MinimalView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        ZStack {
            ActivityProgressRing(state: state, isStale: isStale, lineWidth: 2)
            SessionIcon(state: state, size: 12)
        }
    }
}
