//
//  NativeColorsView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 08/09/25.
//

import SwiftUI

struct NativeColorsView: View {
    private let systemColors: [NamedColor] = [
        .init(name: "systemRed", color: Color(UIColor.systemRed)),
        .init(name: "systemGreen", color: Color(UIColor.systemGreen)),
        .init(name: "systemBlue", color: Color(UIColor.systemBlue)),
        .init(name: "systemOrange", color: Color(UIColor.systemOrange)),
        .init(name: "systemYellow", color: Color(UIColor.systemYellow)),
        .init(name: "systemPink", color: Color(UIColor.systemPink)),
        .init(name: "systemPurple", color: Color(UIColor.systemPurple)),
        .init(name: "systemTeal", color: Color(UIColor.systemTeal)),
        .init(name: "systemIndigo", color: Color(UIColor.systemIndigo)),
        .init(name: "systemBrown", color: Color(UIColor.systemBrown)),
        .init(name: "systemMint", color: Color(UIColor.systemMint)),
        .init(name: "systemCyan", color: Color(UIColor.systemCyan)),
        .init(name: "systemGray", color: Color(UIColor.systemGray)),
        .init(name: "systemGray2", color: Color(UIColor.systemGray2)),
        .init(name: "systemGray3", color: Color(UIColor.systemGray3)),
        .init(name: "systemGray4", color: Color(UIColor.systemGray4)),
        .init(name: "systemGray5", color: Color(UIColor.systemGray5)),
        .init(name: "systemGray6", color: Color(UIColor.systemGray6)),
        .init(name: "label", color: Color(UIColor.label)),
        .init(name: "secondaryLabel", color: Color(UIColor.secondaryLabel)),
        .init(name: "tertiaryLabel", color: Color(UIColor.tertiaryLabel)),
        .init(name: "quaternaryLabel", color: Color(UIColor.quaternaryLabel)),
        .init(name: "link", color: Color(UIColor.link)),
        .init(name: "placeholderText", color: Color(UIColor.placeholderText)),
        .init(name: "separator", color: Color(UIColor.separator)),
        .init(name: "opaqueSeparator", color: Color(UIColor.opaqueSeparator)),
        .init(name: "systemBackground", color: Color(UIColor.systemBackground)),
        .init(name: "secondarySystemBackground", color: Color(UIColor.secondarySystemBackground)),
        .init(name: "tertiarySystemBackground", color: Color(UIColor.tertiarySystemBackground)),
        .init(name: "systemGroupedBackground", color: Color(UIColor.systemGroupedBackground)),
        .init(name: "secondarySystemGroupedBackground", color: Color(UIColor.secondarySystemGroupedBackground)),
        .init(name: "tertiarySystemGroupedBackground", color: Color(UIColor.tertiarySystemGroupedBackground)),
        .init(name: "systemFill", color: Color(UIColor.systemFill)),
        .init(name: "secondarySystemFill", color: Color(UIColor.secondarySystemFill)),
        .init(name: "tertiarySystemFill", color: Color(UIColor.tertiarySystemFill)),
        .init(name: "quaternarySystemFill", color: Color(UIColor.quaternarySystemFill)),
        .init(name: "lightText", color: Color(UIColor.lightText)),
        .init(name: "darkText", color: Color(UIColor.darkText))
    ]
    
    var body: some View {
        List(systemColors) { namedColor in
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(namedColor.color)
                    .frame(width: 50, height: 30)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1)))
                Text(namedColor.name)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("System Colors")
    }
}

struct NamedColor: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

#Preview {
    NativeColorsView()
}

