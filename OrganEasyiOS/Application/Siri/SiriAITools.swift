import AppIntents

#if compiler(>=6.4)
@available(iOS 27.3, *)
extension AddMonthlyEntryIntent: ToolIntent {}

@available(iOS 27.3, *)
extension FindBillsIntent: ToolIntent {}
#endif
