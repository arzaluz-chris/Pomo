// PomoLiveActivityView.swift

import SwiftUI
import WidgetKit
import ActivityKit

struct PomoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoActivityAttributes.self) { context in
            // Lock Screen / banner / StandBy, and the Apple Watch Smart Stack (.small)
            PomoLockScreenView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(context.state.tint)
                .activitySystemActionForegroundColor(Color(pomoHex: 0xFFF4E6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state, isStale: context.isStale)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state, isStale: context.isStale)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(state: context.state, isStale: context.isStale)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state, isStale: context.isStale)
                }
            } compactLeading: {
                CompactLeadingView(state: context.state, isStale: context.isStale)
            } compactTrailing: {
                CompactTrailingView(state: context.state, isStale: context.isStale)
            } minimal: {
                MinimalView(state: context.state, isStale: context.isStale)
            }
            .keylineTint(context.state.islandTint)
        }
        // Custom layout in the Apple Watch Smart Stack (iOS 18 / watchOS 11)
        .supplementalActivityFamilies([.small])
    }
}
