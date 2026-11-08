import SwiftUI

enum InvestmentFormat {
    private static let brl = FloatingPointFormatStyle<Double>.Currency(code: "BRL")

    static func money(_ value: Double?) -> String {
        guard let value else { return "–" }
        return value.formatted(brl)
    }

    static func compactMoney(_ value: Double?) -> String {
        guard let value else { return "–" }
        return value.formatted(brl.notation(.compactName).precision(.fractionLength(0...1)))
    }

    static func compact(_ value: Double?) -> String {
        guard let value else { return "–" }
        return value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
    }

    static func percent(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(2))))%"
    }

    static func signedPercent(_ value: Double?) -> String {
        guard let value else { return "–" }
        return "\(value.formatted(.number.sign(strategy: .always()).precision(.fractionLength(2))))%"
    }

    /// Selic e IPCA somam a taxa ao indexador; o prefixado é a taxa inteira.
    static func treasuryRate(_ asset: InvestmentAsset) -> String {
        guard let rate = asset.rate else { return "–" }
        let value = percent(rate)
        if asset.name.localizedCaseInsensitiveContains("Selic") { return "Selic + \(value)" }
        if asset.name.localizedCaseInsensitiveContains("IPCA") { return "IPCA + \(value)" }
        return value
    }
}

/// Logo do ativo, ou as iniciais quando não há imagem.
struct InvestmentTile: View {
    let asset: InvestmentAsset
    let tint: Color

    private var initials: String {
        String(asset.symbol.prefix(asset.kind == .treasury ? 1 : 4))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [tint, tint.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let url = asset.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit().padding(Size.x4.rawValue)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: 48, height: 48)
    }

    private var initialsView: some View {
        Text(initials)
            .font(.caption)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .padding(Size.x4.rawValue)
    }
}

struct InvestmentTrendChip: View {
    let trend: AssetTrend

    var body: some View {
        Text(trend.title)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(trend.tint)
            .padding(.horizontal, Size.x8.rawValue)
            .padding(.vertical, 3)
            .background(trend.tint.opacity(0.12), in: Capsule())
            .overlay { Capsule().stroke(trend.tint.opacity(0.3), lineWidth: 1) }
    }
}

struct InvestmentRow: View {
    let item: RankedAsset
    let isSaved: Bool
    let tint: Color
    let onOpen: () -> Void
    let onSave: () -> Void

    private var asset: InvestmentAsset { item.asset }

    var body: some View {
        HStack(spacing: Size.x12.rawValue) {
            Button(action: onOpen) {
                HStack(spacing: Size.x12.rawValue) {
                    InvestmentTile(asset: asset, tint: tint)

                    VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                        HStack(spacing: Size.x4.rawValue) {
                            Text("#\(item.position)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(asset.symbol)
                                .font(.headline)
                                .lineLimit(1)
                        }

                        Text(asset.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        HStack(spacing: Size.x8.rawValue) {
                            InvestmentTrendChip(trend: item.trend)
                            Label("\(item.score)", systemImage: "star.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    Spacer(minLength: .zero)

                    VStack(alignment: .trailing, spacing: Size.x4.rawValue) {
                        Text(asset.kind == .treasury ? InvestmentFormat.treasuryRate(asset) : InvestmentFormat.money(asset.price))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        if asset.kind == .treasury {
                            Text(asset.maturity.map { $0.formatted(.dateTime.month(.abbreviated).year()) } ?? "–")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(InvestmentFormat.signedPercent(asset.changePercent))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle((asset.changePercent ?? 0) >= 0 ? .green : .red)
                                .monospacedDigit()
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("assetRow")

            Button(action: onSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
                    .frame(width: 36, height: 36)
                    .overlay { Circle().stroke(Color(.separator), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Salvar")
        }
        .padding(Size.x12.rawValue)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Linha bloqueada. Não leva dado real, para o conteúdo Premium não ficar na tela.
struct InvestmentLockedRow: View {
    let position: Int
    let tint: Color

    var body: some View {
        HStack(spacing: Size.x12.rawValue) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [tint, tint.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: Size.x8.rawValue) {
                RoundedRectangle(cornerRadius: 4).fill(.primary.opacity(0.35)).frame(width: 96, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.3)).frame(width: 140, height: 10)
                RoundedRectangle(cornerRadius: 6).fill(.green.opacity(0.3)).frame(width: 64, height: 16)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Size.x8.rawValue) {
                RoundedRectangle(cornerRadius: 4).fill(.blue.opacity(0.4)).frame(width: 64, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.3)).frame(width: 44, height: 10)
            }
        }
        .padding(Size.x12.rawValue)
        .blur(radius: 4)
        .overlay(alignment: .leading) {
            Text("#\(position)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.leading, Size.x16.rawValue)
        }
        .overlay {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InvestmentPlaceholderRow: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: 92)
            .overlay { ProgressView() }
    }
}

struct InvestmentUnlockBanner: View {
    let lockedCount: Int
    let action: () -> Void

    var body: some View {
        HStack(spacing: Size.x12.rawValue) {
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(lockedCount) ativos no ranking")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Veja a lista completa, com filtros e fundamentos")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            Spacer(minLength: .zero)

            Button(action: action) {
                Text("Assinar")
                    .fontWeight(.semibold)
                    .padding(.horizontal, Size.x8.rawValue)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("investUnlock")
        }
        .padding(Size.x12.rawValue)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}
