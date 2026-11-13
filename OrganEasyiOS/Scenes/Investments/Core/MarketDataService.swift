import Foundation

actor MarketDataService {
    enum ServiceError: Error {
        case unavailable
    }

    static let shared = MarketDataService()

    private enum Source {
        static let market = "https://brapi.dev/api/quote/list"
        static let fundamentals = URL(string: "https://invest-fc7e9.web.app/fundamentals.json")!
        static let treasury = URL(string: "https://invest-fc7e9.web.app/treasury.json")!
        static let crypto = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=brl&order=market_cap_desc&per_page=100&page=1&price_change_percentage=24h")!
        static let selic = URL(string: "https://api.bcb.gov.br/dados/serie/bcdata.sgs.432/dados/ultimos/1?formato=json")!
        static let inflation = URL(string: "https://api.bcb.gov.br/dados/serie/bcdata.sgs.13522/dados/ultimos/1?formato=json")!
        static let cdi = URL(string: "https://api.bcb.gov.br/dados/serie/bcdata.sgs.4389/dados/ultimos/1?formato=json")!
    }

    private enum Constants {
        static let cacheLifetime: TimeInterval = 15 * 60
        static let marketLimit = 1000
    }

    private struct CacheEntry {
        let date: Date
        let assets: [InvestmentAsset]
    }

    private var cache: [InvestmentSector: CacheEntry] = [:]
    private var allStocksCache: CacheEntry?
    private var fundamentals: [String: AssetFundamentals]?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func assets(for sector: InvestmentSector) async throws -> [InvestmentAsset] {
        if let entry = cache[sector], Date.now.timeIntervalSince(entry.date) < Constants.cacheLifetime {
            return entry.assets
        }

        let assets: [InvestmentAsset]
        switch sector {
        case .fixedIncome:
            assets = try MarketParser.treasury(from: await data(Source.treasury))
        case .crypto:
            assets = try MarketParser.crypto(from: await data(Source.crypto))
        case .realEstate:
            assets = try MarketParser.market(from: await data(marketURL(type: "fund")), kind: .fund)
        default:
            async let list = data(marketURL(type: "stock"))
            let companies = try await loadFundamentals()
            assets = try MarketParser.market(from: await list, kind: .stock)
                .filter { sector.marketSectors.contains($0.marketSector ?? "") }
                .map { asset in
                    var asset = asset
                    asset.fundamentals = companies[asset.symbol]
                    return asset
                }
        }

        guard !assets.isEmpty else { throw ServiceError.unavailable }
        cache[sector] = CacheEntry(date: .now, assets: assets)
        return assets
    }

    func allStocks() async throws -> [InvestmentAsset] {
        if let allStocksCache, Date.now.timeIntervalSince(allStocksCache.date) < Constants.cacheLifetime {
            return allStocksCache.assets
        }
        let assets = try MarketParser.market(from: await data(marketURL(type: "stock")), kind: .stock)
        guard !assets.isEmpty else { throw ServiceError.unavailable }
        allStocksCache = CacheEntry(date: .now, assets: assets)
        return assets
    }

    func indicators() async -> MarketIndicators {
        async let selic = latestValue(Source.selic)
        async let inflation = latestValue(Source.inflation)
        async let cdi = latestValue(Source.cdi)
        return await MarketIndicators(selic: selic, inflation: inflation, cdi: cdi)
    }

    private func marketURL(type: String) -> URL {
        var components = URLComponents(string: Source.market)!
        components.queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: String(Constants.marketLimit)),
            URLQueryItem(name: "sortBy", value: "volume"),
            URLQueryItem(name: "sortOrder", value: "desc")
        ]
        return components.url!
    }

    private func loadFundamentals() async throws -> [String: AssetFundamentals] {
        if let fundamentals { return fundamentals }
        guard let data = try? await data(Source.fundamentals) else { return [:] }
        let companies = (try? MarketParser.fundamentals(from: data)) ?? [:]
        fundamentals = companies
        return companies
    }

    private func latestValue(_ url: URL) async -> Double? {
        guard let data = try? await data(url) else { return nil }
        return MarketParser.latestSeriesValue(from: data)
    }

    private func data(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.unavailable
        }
        return data
    }
}

nonisolated enum MarketParser {
    private struct MarketResponse: Decodable {
        struct Item: Decodable {
            let stock: String
            let name: String?
            let close: Double?
            let change: Double?
            let volume: Double?
            let market_cap: Double?
            let logo: String?
            let sector: String?
        }
        let stocks: [Item]
    }

    private struct CryptoItem: Decodable {
        let symbol: String
        let name: String
        let image: String?
        let current_price: Double?
        let market_cap: Double?
        let total_volume: Double?
        let price_change_percentage_24h: Double?
    }

    private struct TreasuryResponse: Decodable {
        struct Title: Decodable {
            let name: String
            let maturity: String
            let rate: Double
            let price: Double
        }
        let titles: [Title]
    }

    private struct FundamentalsResponse: Decodable {
        let companies: [String: AssetFundamentals]
    }

    private struct SeriesPoint: Decodable {
        let valor: String
    }

    static func market(from data: Data, kind: AssetKind) throws -> [InvestmentAsset] {
        try JSONDecoder().decode(MarketResponse.self, from: data).stocks
            .filter { !$0.stock.hasSuffix("F") }
            .map { item in
                InvestmentAsset(
                    symbol: item.stock,
                    name: item.name?.capitalized ?? item.stock,
                    kind: kind,
                    marketSector: item.sector,
                    price: item.close,
                    changePercent: item.change,
                    volume: item.volume,
                    marketCap: item.market_cap,
                    imageURL: nil
                )
            }
    }

    static func crypto(from data: Data) throws -> [InvestmentAsset] {
        try JSONDecoder().decode([CryptoItem].self, from: data).map { item in
            InvestmentAsset(
                symbol: item.symbol.uppercased(),
                name: item.name,
                kind: .crypto,
                price: item.current_price,
                changePercent: item.price_change_percentage_24h,
                volume: item.total_volume,
                marketCap: item.market_cap,
                imageURL: item.image.flatMap(URL.init(string:))
            )
        }
    }

    static func treasury(from data: Data) throws -> [InvestmentAsset] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        return try JSONDecoder().decode(TreasuryResponse.self, from: data).titles.map { title in
            let maturity = formatter.date(from: title.maturity)
            let year = maturity.map { Calendar.current.component(.year, from: $0) }
            return InvestmentAsset(
                symbol: "\(title.name) \(year.map(String.init) ?? "")".trimmingCharacters(in: .whitespaces),
                name: title.name,
                kind: .treasury,
                price: title.price,
                rate: title.rate,
                maturity: maturity
            )
        }
    }

    static func fundamentals(from data: Data) throws -> [String: AssetFundamentals] {
        try JSONDecoder().decode(FundamentalsResponse.self, from: data).companies
    }

    static func latestSeriesValue(from data: Data) -> Double? {
        (try? JSONDecoder().decode([SeriesPoint].self, from: data))?.last.flatMap { Double($0.valor) }
    }
}
