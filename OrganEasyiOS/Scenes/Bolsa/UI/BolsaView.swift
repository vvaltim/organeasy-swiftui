import Combine
import SwiftUI

@MainActor
final class BolsaModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var state = State.loading
    @Published private(set) var desks: [BolsaDesk] = []
    @Published private(set) var updatedAt: Date?

    var gainers: Int { desks.filter(\.isUp).count }
    var losers: Int { desks.count - gainers }

    func load() async {
        if desks.isEmpty, updatedAt == nil { state = .loading }
        do {
            let stocks = try await MarketDataService.shared.allStocks()
            desks = BolsaBoard.desks(from: stocks)
            updatedAt = .now
            state = .loaded
        } catch {
            state = updatedAt == nil ? .failed : .loaded
        }
    }
}

struct BolsaView: View {
    let onOpenInvestments: () -> Void

    @StateObject private var model = BolsaModel()
    @State private var selected: BolsaDesk?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Size.x12.rawValue) {
                    header

                    if !BolsaMarketClock.isOpen() {
                        closedNotice
                    }

                    switch model.state {
                    case .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 240)
                    case .failed:
                        failureView
                    case .loaded:
                        if model.desks.isEmpty {
                            ContentUnavailableView(
                                "Sem variações no último pregão",
                                systemImage: "equal.circle",
                                description: Text("Puxe para atualizar mais tarde.")
                            )
                        } else {
                            BolsaOfficeView(desks: model.desks) { selected = $0 }
                        }
                    }

                    disclaimer
                }
                .padding(.horizontal)
                .padding(.bottom, Size.x16.rawValue)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bolsa hoje")
            .refreshable { await model.load() }
        }
        .task { await model.load() }
        .sheet(item: $selected) { desk in
            BolsaDeskCard(desk: desk) {
                selected = nil
                onOpenInvestments()
            }
            .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: Size.x12.rawValue) {
            Label("\(model.gainers) altas", systemImage: "arrowtriangle.up.fill")
                .foregroundStyle(.green)
            Label("\(model.losers) baixas", systemImage: "arrowtriangle.down.fill")
                .foregroundStyle(.red)
            Spacer()
            if let updatedAt = model.updatedAt {
                Text("Atualizado às \(updatedAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var closedNotice: some View {
        Label("Mercado fechado: mostrando o último pregão", systemImage: "moon.zzz.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Size.x12.rawValue)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label("Não foi possível carregar", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Verifique sua conexão e tente de novo.")
        } actions: {
            Button("Tentar novamente") {
                Task { await model.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var disclaimer: some View {
        Text("Maiores altas e baixas entre as ações mais negociadas, com dados públicos e atraso. Não é recomendação de investimento.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, Size.x4.rawValue)
    }
}
