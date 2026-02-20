// PomoLiveActivityView.swift

import SwiftUI
import WidgetKit
import ActivityKit

struct PomoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            PomoLockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(state: context.state)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }
            } compactLeading: {
                CompactLeadingView(state: context.state)
            } compactTrailing: {
                CompactTrailingView(state: context.state)
            } minimal: {
                MinimalView(state: context.state)
            }
        }
    }
}
