//
//  GlassEffectIfAvailable.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 02/07/25.
//

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: 24.00))
        } else {
            content
        }
        content
    }
}
