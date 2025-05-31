// DurationSlider.swift

import SwiftUI

struct DurationSlider: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(value) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .tint(.pomoPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DurationSlider(
        title: "Trabajo",
        value: .constant(25),
        range: 10...60
    )
    .padding()
}
