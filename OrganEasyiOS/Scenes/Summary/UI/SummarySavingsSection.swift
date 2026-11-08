import SwiftUI

struct SummaryVideoNotice: View {
    let hasAccess: Bool

    @ObservedObject private var access = SummaryAIAccess.shared

    var body: some View {
        if !hasAccess {
            Text(access.wasVideoDismissed
                ? "Assista ao vídeo até o fim para continuar."
                : "Um vídeo curto libera estes recursos por 30 minutos.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SummarySavingsSection: View {
    let entries: [SummaryEntry]

    @ObservedObject private var access = SummaryAIAccess.shared
    @ObservedObject private var store = PurchaseStore.shared

    @State private var suggestions: [SavingsSuggestion]?

    private var hasAccess: Bool {
        store.isAdsRemoved || access.isUnlocked
    }

    var body: some View {
        let available = SavingsAdvisor.suggestions(entries: entries)

        if !available.isEmpty {
            Section("Como economizar") {
                if let suggestions {
                    ForEach(suggestions) { suggestion in
                        Text(suggestion.text)
                            .font(.subheadline)
                    }
                } else {
                    Button {
                        access.perform(hasAccess: hasAccess) { suggestions = available }
                    } label: {
                        Text("Ver sugestões")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(access.isLoadingVideo)
                    .accessibilityIdentifier("savingsButton")

                    SummaryVideoNotice(hasAccess: hasAccess)
                }
            }
        }
    }
}
