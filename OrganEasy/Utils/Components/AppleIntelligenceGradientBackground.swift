//
//  AppleIntelligenceGradientBackground.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 08/10/25.
//

import SwiftUI

struct AppleIntelligenceGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var angle: Angle = .degrees(0)
    @State private var gradientOpacityDark: Double = 0.9
    @State private var gradientOpacityLight: Double = 0.3

    var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.6, green: 0.15, blue: 0.38),
                Color(red: 0.7, green: 0.35, blue: 0.10),
                Color(red: 0.0, green: 0.38, blue: 0.35),
                Color(red: 0.10, green: 0.34, blue: 0.45),
                Color(red: 0.39, green: 0.16, blue: 0.47),
                Color(red: 0.6, green: 0.15, blue: 0.38)
            ]
        } else {
            return [
                Color(red: 1.0, green: 0.35, blue: 0.78),
                Color(red: 1.0, green: 0.70, blue: 0.25),
                Color(red: 0.0, green: 0.78, blue: 0.75),
                Color(red: 0.20, green: 0.68, blue: 0.90),
                Color(red: 0.69, green: 0.32, blue: 0.87),
                Color(red: 1.0, green: 0.35, blue: 0.78)
            ]
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .ignoresSafeArea()
            
            AngularGradient(
                gradient: Gradient(colors: gradientColors),
                center: .center
            )
            .blur(radius: 100)
            .scaleEffect(3)
            .rotationEffect(angle)
            .opacity(colorScheme == .dark ? gradientOpacityDark : gradientOpacityLight)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 4).repeatForever(autoreverses: false)
                ) {
                    angle = .degrees(360)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        gradientOpacityDark = 0
                        gradientOpacityLight = 0
                    }
                }
            }
        }
        
    }
}

#Preview {
    AppleIntelligenceGradientBackground()
}
