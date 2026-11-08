import SwiftUI

/// Primeira entrada abre o onboarding; depois, a lista do perfil escolhido.
struct InvestmentsView: View {
    @ObservedObject private var profile = InvestorProfileStore.shared

    var body: some View {
        if let risk = profile.risk, let sector = profile.sector {
            InvestmentListView(risk: risk, sector: sector)
        } else {
            InvestmentOnboardingView()
        }
    }
}
