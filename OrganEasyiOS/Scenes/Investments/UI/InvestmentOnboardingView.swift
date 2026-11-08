import SwiftUI

struct InvestmentOnboardingView: View {
    private enum Step: Int, CaseIterable {
        case intro
        case risk
        case sector
        case building
    }

    @ObservedObject private var profile = InvestorProfileStore.shared

    @State private var step = Step.intro
    @State private var risk: RiskProfile?
    @State private var sector: InvestmentSector?

    var body: some View {
        VStack(spacing: Size.x16.rawValue) {
            if step != .intro {
                ProgressView(value: Double(step.rawValue), total: Double(Step.allCases.count - 1))
                    .tint(risk?.tint ?? .blue)
                    .padding(.horizontal)
                    .animation(.easeInOut, value: step)
            }

            Group {
                switch step {
                case .intro: intro
                case .risk: riskStep
                case .sector: sectorStep
                case .building: building
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }
        .padding(.top, Size.x8.rawValue)
        .background(Color(.systemGroupedBackground))
        .task { InvestmentEvent.onboardingStarted.log() }
    }

    private var intro: some View {
        VStack(spacing: Size.x24.rawValue) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: Size.x8.rawValue) {
                Text("Veja o que se destaca no mercado")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Monte seu perfil em 1 minuto e compare ações, fundos, Tesouro e cripto com dados públicos.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Size.x12.rawValue) {
                benefit("number.circle.fill", "Ranking com nota de 0 a 100")
                benefit("doc.text.magnifyingglass", "Fundamentos dos balanços oficiais")
                benefit("slider.horizontal.3", "Filtros para achar o que importa para você")
            }

            Spacer()

            primaryButton("Começar") { advance(to: .risk) }
                .accessibilityIdentifier("onboardingStart")
        }
        .padding()
    }

    private func benefit(_ icon: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.blue)
        }
        .font(.subheadline)
    }

    private var riskStep: some View {
        VStack(alignment: .leading, spacing: Size.x16.rawValue) {
            header("Qual risco você aceita?", "Isso muda como a nota de cada ativo é calculada.")

            ScrollView {
                VStack(spacing: Size.x12.rawValue) {
                    ForEach(RiskProfile.allCases) { option in
                        riskCard(option)
                    }
                }
                .padding(.horizontal)
            }

            primaryButton("Continuar") { advance(to: .sector) }
                .disabled(risk == nil)
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityIdentifier("onboardingRiskContinue")
        }
    }

    private func riskCard(_ option: RiskProfile) -> some View {
        let isSelected = risk == option

        return Button {
            withAnimation(.spring(duration: 0.25)) { risk = option }
            InvestmentEvent.riskSelected(option).log()
        } label: {
            HStack(alignment: .top, spacing: Size.x12.rawValue) {
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : option.tint)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? option.tint : option.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                    Text(option.title)
                        .font(.headline)
                    Text(option.summary)
                        .font(.subheadline)
                    Text(option.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: .zero)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? option.tint : .secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? option.tint : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("risk_\(option.rawValue)")
    }

    private var sectorStep: some View {
        VStack(alignment: .leading, spacing: Size.x16.rawValue) {
            header("Qual setor mais te interessa?", "Escolha 1 para começar.")

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Size.x12.rawValue) {
                    ForEach(InvestmentSector.allCases) { option in
                        sectorCard(option)
                    }
                }
                .padding(.horizontal)
            }

            primaryButton("Ver meu ranking") { finish() }
                .disabled(sector == nil)
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityIdentifier("onboardingFinish")
        }
    }

    private func sectorCard(_ option: InvestmentSector) -> some View {
        let isSelected = sector == option

        return Button {
            withAnimation(.spring(duration: 0.25)) { sector = option }
            InvestmentEvent.sectorSelected(option).log()
        } label: {
            VStack(alignment: .leading, spacing: Size.x12.rawValue) {
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : option.tint)
                Text(option.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .padding()
            .background(isSelected ? option.tint : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sector_\(option.rawValue)")
    }

    private var building: some View {
        VStack(spacing: Size.x16.rawValue) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Montando seu ranking")
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func finish() {
        guard let risk, let sector else { return }
        advance(to: .building)
        InvestmentEvent.onboardingCompleted(risk, sector).log()

        Task {
            try? await Task.sleep(for: .seconds(1))
            withAnimation { profile.save(risk: risk, sector: sector) }
        }
    }

    private func advance(to next: Step) {
        withAnimation(.easeInOut(duration: 0.3)) { step = next }
    }

    private func header(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Size.x4.rawValue) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private func primaryButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
