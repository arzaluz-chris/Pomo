// PomoWatchWidgetExtension/PomoWatchWidgetBundle.swift

import WidgetKit
import SwiftUI

@main
struct PomoWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomoCircularComplication()
        PomoInlineComplication()
        PomoRectangularComplication()
        PomoCornerComplication()
    }
}
