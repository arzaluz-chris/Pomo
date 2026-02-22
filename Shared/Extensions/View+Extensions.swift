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
        #if os(watchOS)
        return self
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(16)
        #else
        return self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        #endif
    }
}
