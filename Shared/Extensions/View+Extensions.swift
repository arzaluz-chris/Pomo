// View+Extensions.swift

import SwiftUI

extension View {
    func pomoButtonStyle() -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.UI.buttonHeight)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(Constants.UI.cornerRadius)
    }
    
    func pomoCard() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
    }
}
