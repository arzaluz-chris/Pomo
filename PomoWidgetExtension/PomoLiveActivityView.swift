// PomoLiveActivityView.swift

import SwiftUI
import WidgetKit
import ActivityKit

struct PomoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoActivityAttributes.self) { context in
            // Lock Screen / banner / StandBy, and the Apple Watch Smart Stack (.small)
            PomoLockScreenView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(state: context.state, isStale: context.isStale)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state, isStale: context.isStale)
                }
            } compactLeading: {
                CompactLeadingView(state: context.state)
            } compactTrailing: {
                CompactTrailingView(state: context.state, isStale: context.isStale)
            } minimal: {
                MinimalView(state: context.state, isStale: context.isStale)
            }
            .keylineTint(context.state.tint)
        }
        // Custom layout in the Apple Watch Smart Stack (iOS 18 / watchOS 11)
        .supplementalActivityFamilies([.small])
    }
}
