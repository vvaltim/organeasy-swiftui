//
//  Color+extensions.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/03/26.
//

import SwiftUI

extension Color {
    static var groupedBackground: Color {
        #if os(iOS)
        // Use explicit UIColor to avoid contextual type resolution issues
        return Color(UIColor.secondarySystemGroupedBackground)
        #elseif os(macOS)
        // NSColor.secondaryGroupedContentBackground does not exist on macOS; use a close system background
        return Color(NSColor.windowBackgroundColor)
        #else
        // Fallback to a neutral system background on other platforms
        return Color(.systemBackground)
        #endif
    }
}
