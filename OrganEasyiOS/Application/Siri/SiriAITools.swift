import AppIntents

// A Siri AI existe a partir do iOS 27.3. Com compiladores anteriores o bloco some
// e o app continua igual, inclusive para quem está no iOS 26.
#if compiler(>=6.4)
@available(iOS 27.3, *)
extension AddMonthlyEntryIntent: ToolIntent {}

@available(iOS 27.3, *)
extension FindBillsIntent: ToolIntent {}
#endif
